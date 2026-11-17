#!/usr/bin/env perl
# suite.pl is read as UTF-8 source (k60, ADR 0007 amendment k60), on invented suites
# (ADR 0003).
# Claims: a suite.pl with non-ASCII text and no `use utf8` sends the model the
# characters the author wrote -- checked in the outgoing request of a run against
# Langertha::Engine::Virtual (system prompt, message, tool description), not only in
# the loaded structure; a suite.pl that says `use utf8` itself loads the same suite
# (the same digest); a text read by `file` arrives decoded; the YAML export of such a
# suite loads back with the same digest and holds the characters as UTF-8; a
# suite.pl that is not valid UTF-8 is refused with the field suite.pl instead of
# loading as Latin-1.
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Path::Tiny qw( path );
use Test::More;
binmode( Test::More->builder->$_, ":encoding(UTF-8)" ) for qw( output failure_output todo_output );

use Langertha::Engine::Virtual;
use Langertha::Virtual::Rules qw( tool answer );
use Langertha::Holmgang::Loader;
use Langertha::Holmgang::Runner;
use Langertha::Holmgang::Target;

my $tmp = Path::Tiny->tempdir;

my $ASK    = 'Stell die Größe auf „groß“ – jetzt.';
my $PROMPT = 'Antworte über das Werkzeug.';
my $DESC   = 'Setzt die Größe – nur klein oder groß.';
my $FILE   = "Hinweis aus der Datei: Übergröße ist verboten.\n";

# the suite.pl as characters; written to disk as UTF-8 bytes, like an editor does
sub suite_pl {
  my ( $id, %o ) = @_;
  my $pragma = $o{use_utf8} ? "use utf8;\n" : '';
  return <<"P";
use Langertha::Holmgang;
$pragma
suite '$id' => sub {
  title   'Umlaute';
  version 1;
  system_prompt '$PROMPT';
  tool set_size => (
    description => '$DESC',
    parameters  => { type => 'object', required => ['size'], properties => { size => { type => 'string' } } },
    handlers    => [ handler apply => [ { set => 'size', value => '{size}' } ], output => 'ok' ],
  );
  case 'size-01' => sub {
    title 'Größe setzen';
    world size => undef;
    ask '$ASK';
    message assistant => 'Verstanden.';
    ask file 'hinweis.txt';
    rule 'Größe groß' => at 'size', equals => 'groß';
    rule 'nichts sonst' => unchanged_except ['size'];
    solution call set_size => { size => 'groß' };
    alternative 'erst klein' => call( set_size => { size => 'klein' } ), call( set_size => { size => 'groß' } );
    wrong 'klein' => call set_size => { size => 'klein' };
  };
};
P
}

sub dsl_dir {
  my ( $root, $id, $code ) = @_;
  my $d = path( $root, $id );
  $d->mkpath;
  $d->child('suite.pl')->spew_utf8($code);
  $d->child('hinweis.txt')->spew_utf8($FILE);
  return "$d";
}

my $loader = Langertha::Holmgang::Loader->new;

sub first_request {
  my ( $suite ) = @_;
  my $e = Langertha::Engine::Virtual->new( script => [ tool( set_size => { size => 'groß' } ), answer('Fertig.') ] );
  my $r = Langertha::Holmgang::Runner->new( target => Langertha::Holmgang::Target->new( engine => $e ) )
    ->run_case( $suite->cases->[0] );
  return ( $r, $e->requests->[0]{body} );
}

# --- without use utf8: what the model is sent ---------------------------------------
my $plain = $loader->load( dsl_dir( $tmp->child('plain'), 'ex-umlaut', suite_pl('ex-umlaut') ) );
{
  my ( $r, $body ) = first_request($plain);
  is( $r->{status}, 'passed', 'without use utf8: the run passes on the right characters' ) or diag explain $r;
  my @msg = @{ $body->{messages} };
  is( $msg[0]{role}, 'system', 'the first message is the system prompt' );
  is( $msg[0]{content}, $PROMPT, '... sent as written, not as Latin-1 mojibake' );
  is( $msg[1]{content}, $ASK, 'the case message is sent as written (umlauts, dashes, quotes)' );
  is( $msg[3]{content}, $FILE, 'a text read by file is sent decoded' );
  my ($t) = map { $_->{function} // $_ } @{ $body->{tools} };
  is( $t->{description}, $DESC, 'the tool description is sent as written' );
  unlike( join( "\n", map { $_->{content} } @msg ), qr/Ã|â€/, 'no mojibake anywhere in the messages' );
}

# --- with use utf8: the same suite --------------------------------------------------
my $explicit = $loader->load( dsl_dir( $tmp->child('explicit'), 'ex-umlaut', suite_pl( 'ex-umlaut', use_utf8 => 1 ) ) );
is( $explicit->digest, $plain->digest, 'a suite.pl that says use utf8 itself is the same suite (same digest)' );
{
  my ( $r, $body ) = first_request($explicit);
  is( $r->{status}, 'passed', '... and its run passes' );
  is( $body->{messages}[1]{content}, $ASK, '... and sends the same characters' );
}

# --- the YAML export ----------------------------------------------------------------
{
  my $out = $loader->export( $tmp->child('plain')->child('ex-umlaut'), $tmp->child('export') );
  my $yaml = $loader->load($out);
  is( $yaml->digest, $plain->digest, 'the export loads back with the same digest' );
  my $bytes = path( $out, 'cases', 'size-01.yaml' )->slurp_raw;
  my $want  = $ASK;
  utf8::encode($want);
  like( $bytes, qr/\Q$want\E/, '... and holds the message as UTF-8, not double-encoded' );
  my ( undef, $body ) = first_request($yaml);
  is( $body->{messages}[1]{content}, $ASK, '... and the export sends the same characters' );
}

# --- not UTF-8: refused, not loaded as Latin-1 --------------------------------------
{
  my $d = path( $tmp, 'latin1', 'ex-latin1' );
  $d->mkpath;
  my $code = suite_pl('ex-latin1');
  $code =~ s/[^\x00-\xff]/-/g;    # Latin-1 characters only (umlauts stay)
  utf8::downgrade($code);           # the bytes are Latin-1, not UTF-8
  $d->child('suite.pl')->spew_raw($code);
  $d->child('hinweis.txt')->spew_utf8($FILE);
  my $ok = eval { $loader->load("$d"); 1 };
  ok( !$ok, 'a suite.pl in Latin-1 is refused' );
  like( "$@", qr/^suite\.pl\b.*UTF-8/s, '... with the field suite.pl and the reason' ) or diag "$@";
}

done_testing;
