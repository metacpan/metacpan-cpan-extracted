use strict;
use warnings;
use Test::More;

use Test::InDistDir;
use Test::Warn;
use Test::Fatal;
use Path::Tiny;
use JSON::PP qw( decode_json );
use Locale::Simple::PO2JSON qw( po2data data2json );

my $test = 't/data/locale/de_DE/LC_MESSAGES/test.po';
my $d = po2data($test);
is $d->{''}{Language}, 'de_DE', 'header trimmed';
is $d->{''}{lang},     'de_DE', 'lang from Language';
is_deeply $d->{"alien\x04Hello"}, [ undef, 'Hallo Ausserirdischer' ], 'context key';
is_deeply $d->{'You have %d message'},
  [ 'You have %d messages', 'Du hast %d Nachricht', 'Du hast %d Nachrichten' ], 'plural';
is_deeply [ keys %{ po2data( $test, domain => 'myapp' ) } ], ['myapp'], 'domain wrap';
is_deeply decode_json( path('t/data/po2json/test.expected.json')->slurp_raw ), $d, 'golden';

my $e = po2data('t/data/po2json/edge.po');
is $e->{multi}[1], "Zeile 1\nZeile 2", 'multi-line joined';
is $e->{esc}[1],   "Ein \"Zitat\", ein \\ und ein\tTab", 'escapes';
is $e->{Size}[1],  "Gr\x{f6}\x{df}e \x{2192}", 'utf8 decoded';
ok !exists $e->{$_}, "$_ skipped" for qw(fuzzy empty old);
is scalar @{ $e->{'%d file'} }, 4, 'three plural forms + msgid_plural';
is_deeply decode_json( data2json($e) ), $e, 'json round-trip keeps utf8';
is data2json($e), data2json($e), 'canonical';
like data2json( $e, pretty => 1 ), qr/\n   /, 'pretty';
unlike data2json($e), qr/\n\z/, 'no trailing newline';
unlike data2json( $e, pretty => 1 ), qr/\n\z/, 'no trailing newline when pretty';
warnings_like { po2data('t/data/po2json/noplural.po') } [qr/Plural-Forms/], 'warns once';
like exception { po2data('t/data/po2json/missing.po') },
  qr{\ACannot read PO file t/data/po2json/missing\.po: [^\n]+\n\z}, 'missing';
unlike exception { po2data('t/data/po2json/missing.po') }, qr/ at \S+ line \d+/, 'no Perl location';

# Several quoted strings on one line, and comments that start with whitespace.
# The expectations are what msgfmt writes for t/data/po2json/strings.po
# (msgfmt -o x.mo strings.po; msgunfmt x.mo): "twoparts" => "einzwei", "abc" => "xyz".
my $s = po2data('t/data/po2json/strings.po');
is $s->{twoparts}[1], 'einzwei', 'several strings on one line are joined';
is $s->{abc}[1],      'xyz',     'strings across lines and on one line are joined';
is $s->{esc}[1],      'q"uote\\', 'escapes inside joined strings';
ok !exists $s->{two},   'the first string alone is not a msgid';
ok !exists $s->{"two\" \"parts"}, 'the quotes between the strings are dropped';
is scalar( grep { length } keys %{$s} ), 3, 'an indented comment does not end up in an entry';

my $tmp = Path::Tiny->tempdir;
my $n   = 0;
my $broken = sub {
    my ($content) = @_;
    my $f = $tmp->child( 'b' . $n++ . '.po' );
    $f->spew_utf8($content);
    return ( "$f", exception { po2data("$f") } );
};
my %cases = (
    'syntax error'                => [ "msgid \"a\"\nmsgstr \"b\"\n\nbogus\n", 4, 'syntax error' ],
    'unknown escape'              => [ "msgid \"a\"\nmsgstr \"b\\q\"\n", 2, 'unknown escape sequence \\\\q' ],
    'msgid repeated'              => [ "msgid \"a\"\nmsgid \"b\"\n", 2, 'msgid not allowed here' ],
    'msgctxt after msgid'         => [ "msgid \"a\"\nmsgctxt \"c\"\n", 2, 'msgctxt not allowed here' ],
    'msgid_plural without msgid'  => [ "msgid_plural \"a\"\n", 1, 'msgid_plural without msgid' ],
    'msgstr without msgid'        => [ "msgstr \"a\"\n", 1, 'msgstr without msgid' ],
    'msgstr[1] without msgid'     => [ "msgstr[1] \"a\"\n", 1, 'msgstr\[1\] without msgid' ],
    'string without keyword'      => [ "\"a\"\n", 1, 'string without keyword' ],
);
for my $name ( sort keys %cases ) {
    my ( $content, $line, $reason ) = @{ $cases{$name} };
    my ( $f, $err ) = $broken->($content);
    like $err, qr/\A\Q$f\E line $line: $reason\n\z/, "parse error: $name";
}

my ( $bad, $err ) = do {
    my $f = $tmp->child('latin1.po');
    $f->spew_raw("msgid \"a\"\nmsgstr \"\xe4\"\n");
    ( "$f", exception { po2data("$f") } );
};
like $err, qr/\ACannot read PO file \Q$bad\E: not valid UTF-8\n\z/, 'invalid UTF-8';

done_testing;
