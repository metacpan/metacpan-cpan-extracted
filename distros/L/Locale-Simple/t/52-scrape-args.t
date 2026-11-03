use strict;
use warnings;
use Test::More;

use Test::InDistDir;
use Capture::Tiny 'capture';
use Cwd 'getcwd';
use File::Temp 'tempdir';
use Locale::Simple::Scraper 'scrape';

# Only the msgid, the plural msgid, the context and the domain have to be
# constant strings. The count and the arguments after them are code in the
# fixture's language: variables, member access, calls, casts, brackets,
# strings holding a comma or a closing bracket, calls over several lines.
# Every call is extracted once, and so is every translation call inside
# those arguments. A call whose msgid is not a constant string is skipped,
# the translation calls inside it are not.

sub entry {
    my ( $msgid, %more ) = @_;
    return { msgid => $msgid, %more };
}

sub plural {
    my ( $msgid, $msgid_plural, %more ) = @_;
    return { msgid => $msgid, msgid_plural => $msgid_plural, %more };
}

my %expected = (
    pl => [
        entry('PL var %s'),
        entry('PL assign %s'),
        plural( 'PL count one', 'PL count many' ),
        plural( 'PL zero one',  'PL zero many' ),
        plural( 'PL method %d', 'PL methods %d' ),
        plural( 'PL fn %d',     'PL fns %d' ),
        entry('PL paren %s'),
        entry('PL comma %s %s'),
        entry('PL escape %s'),
        entry('PL nested %s and %s'),
        entry('PL Apple'),
        entry( 'PL ctx %s', msgctxt => 'PL_ctx' ),
        plural( 'PL dnp one', 'PL dnp many', msgctxt => 'PL_ctx', domain => 'PL_dom' ),
        entry('PL multi %s %s'),
        plural( 'PL multi one',        'PL multi many' ),
        plural( 'PL nested count one', 'PL nested count many' ),
        entry('PL in count'),
        entry('PL inside skipped'),
        entry('PL once'),
    ],
    js => [
        entry('JS var %s'),
        entry('JS assign %s'),
        plural( 'JS count one', 'JS count many' ),
        plural( 'JS member %d', 'JS members %d' ),
        plural( 'JS fn %d',     'JS fns %d' ),
        entry('JS paren %s'),
        entry('JS comma %s %s'),
        entry('JS escape %s'),
        entry('JS template %s'),
        entry('JS nested %s and %s'),
        entry('JS Apple'),
        plural( 'JS ctx one', 'JS ctx many', msgctxt => 'JS_ctx' ),
        entry('JS multi %s %s'),
        plural( 'JS nested count one', 'JS nested count many' ),
        entry('JS in count'),
        entry('JS inside skipped'),
    ],
    py => [
        entry('PY var %s'),
        entry('PY assign %s'),
        plural( 'PY count one', 'PY count many' ),
        plural( 'PY len %d',    'PY lens %d' ),
        plural( 'PY attr %d',   'PY attrs %d' ),
        entry('PY paren %s'),
        entry('PY comma %s %s'),
        entry('PY escape %s'),
        entry('PY nested %s and %s'),
        entry('PY Apple'),
        plural( 'PY dom one', 'PY dom many', domain => 'PY_dom' ),
        entry('PY multi %s %s'),
        plural( 'PY nested count one', 'PY nested count many' ),
        entry('PY in count'),
        entry('PY inside skipped'),
    ],
    php => [
        entry('PHP var %s'),
        entry('PHP assign %s'),
        plural( 'PHP count one',   'PHP count many' ),
        plural( 'PHP method %d',   'PHP methods %d' ),
        plural( 'PHP count fn %d', 'PHP count fns %d' ),
        entry('PHP paren %s'),
        entry('PHP comma %s %s'),
        entry('PHP escape %s'),
        entry('PHP heredoc arg %s'),
        entry('PHP nested %s and %s'),
        entry('PHP Apple'),
        entry( 'PHP ctx %s', msgctxt => 'PHP_ctx' ),
        entry('PHP multi %s %s'),
        plural( 'PHP nested count one', 'PHP nested count many' ),
        entry('PHP in count'),
        entry('PHP inside skipped'),
    ],
    go => [
        entry('Go var %s'),
        entry('Go assign %s'),
        plural( 'Go count one', 'Go count many' ),
        plural( 'Go len %d',    'Go lens %d' ),
        plural( 'Go field %d',  'Go fields %d' ),
        entry('Go paren %s'),
        entry('Go comma %s %s'),
        entry('Go escape %s'),
        entry('Go rune %c'),
        entry('Go nested %s and %s'),
        entry('Go Apple'),
        plural( 'Go dnp one', 'Go dnp many', msgctxt => 'Go_ctx', domain => 'Go_dom' ),
        entry('Go multi %s %s'),
        plural( 'Go nested count one', 'Go nested count many' ),
        entry('Go in count'),
        entry('Go inside skipped'),
    ],
    rs => [
        entry('Hello %s'),
        entry('Rust assign %s'),
        plural( 'Rust count one', 'Rust count many' ),
        plural( '%d file',        '%d files' ),
        plural( 'Rust cast %d',   'Rust casts %d' ),
        entry('Rust paren %s'),
        entry('Rust comma %s %s'),
        entry('Rust escape %s'),
        entry('Rust char %c'),
        entry('Rust nested %s and %s'),
        entry('Rust Apple'),
        entry( 'Rust dp %s', msgctxt => 'Rust_ctx', domain => 'Rust_dom' ),
        entry('Rust multi %s %s'),
        plural( 'Rust nested count one', 'Rust nested count many' ),
        entry('Rust in count'),
        entry('Rust inside skipped'),
    ],
);

for my $lang ( qw( pl js py php go rs ) ) {
    my $got = scrape_entries("args.$lang");
    is_deeply( $got, sorted( $expected{$lang} ), "$lang: every call is extracted once" )
      or diag explain $got;
}

# A bracket that never closes, here an escaped one in a regular expression
# (a literal form the scraper does not know), runs the argument on to the
# end of the file. Call after call of that must still be read in no time.
{
    my $dir = tempdir( CLEANUP => 1 );
    open my $fh, '>', "$dir/unclosed.js" or die "cannot write $dir/unclosed.js: $!";
    my $func = lc 'L';    # so t/50-scrape.t finds no call in this file
    print {$fh} qq{$func("Unclosed $_ %s", s.replace(/\\(/g, ""));\n} for 1 .. 40;
    close $fh;

    my $cwd = getcwd;
    chdir $dir or die "cannot chdir to $dir: $!";
    my $finished = eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 60;
        capture { scrape( '--output', 'perl' ) };
        alarm 0;
        1;
    };
    chdir $cwd or die "cannot chdir back to $cwd: $!";
    ok( $finished, 'forty calls with a bracket that never closes are read in time' ) or diag $@;
}

done_testing;

# Every call the scraper found in one fixture, without file and line, in a
# stable order. Duplicates stay, so a call found twice shows up.
sub scrape_entries {
    my ($file) = @_;

    my ($out) = capture {
        scrape( '--only', "arg-fixtures/\Q$file\E", '--output', 'perl' );
    };

    my $VAR1;
    eval "$out; 1" or die "cannot read the scraper output: $@";

    my @entries = map {
        my $found = $_;
        +{ map { defined $found->{$_} ? ( $_ => $found->{$_} ) : () } qw( msgid msgid_plural msgctxt domain ) }
    } @{$VAR1};
    return sorted( \@entries );
}

sub sorted {
    my ($entries) = @_;
    my $key = sub {
        my ($e) = @_;
        join "\0", map { $e->{$_} // '' } qw( domain msgctxt msgid msgid_plural );
    };
    return [ sort { $key->($a) cmp $key->($b) } @{$entries} ];
}
