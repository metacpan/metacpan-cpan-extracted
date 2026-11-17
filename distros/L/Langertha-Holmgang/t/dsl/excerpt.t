#!/usr/bin/env perl
# The DSL constructor `excerpt` (k52, ADR 0007 amendment k52) and its YAML export,
# on an invented statute and suite (ADR 0003).
# Claims: `excerpt FILE, from => …, to => …` is the format 2 part
# { auszug => { datei, von, bis } }, alone or in a list of parts, and misuse dies at
# its line; a DSL suite with excerpts loads (the excerpt set in, the spec never sent);
# a bad range is refused with the case and the field; the export writes the part as
# it is and copies the fixture under quellen/ byte for byte (nothing else of
# quellen/), and the export loads back with the same digest and the same text sent.
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Encode ();
use Path::Tiny qw( path );
use Test::More;
use YAML::XS ();

use Langertha::Holmgang ();
use Langertha::Holmgang::Error;
use Langertha::Holmgang::Loader;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

subtest 'the constructor' => sub {
  is_deeply( Langertha::Holmgang::excerpt( 'quellen/lfg.txt', from => '§ 2', to => '§ 3' ),
    { auszug => { datei => 'quellen/lfg.txt', von => '§ 2', bis => '§ 3' } }, 'the format 2 part' );
  my @bad = (
    [ [ undef, from => '§ 1', to => '§ 2' ],            qr/a file under quellen\/ expected/ ],
    [ [ 'quellen/lfg.txt', 'from' ],                     qr/pairs expected/ ],
    [ [ 'quellen/lfg.txt', from => '§ 1', bis => '§ 2' ], qr/unknown key 'bis'/ ],
    [ [ 'quellen/lfg.txt', from => '§ 1', to => [] ],    qr/to => the label of a provision expected/ ],
    [ [ 'quellen/lfg.txt', to => '§ 1' ],                qr/from => the label/ ],
  );
  for my $b (@bad) {
    my $line = __LINE__ + 1;
    my $err  = eval { Langertha::Holmgang::excerpt( @{ $b->[0] } ); 1 } ? 'lived' : "$@";
    like( $err, qr/\Aexcerpt: .*$b->[1].* at \Q$0\E line $line\./s, "dies at its line: $b->[1]" );
  }
};

my $tmp  = Path::Tiny->tempdir;
my $root = path( $tmp, 'dsl' );
my $dir  = $root->child('law');
my $law  = "Titel: Leuchtfeuergesetz (LfG)\nStand: erfunden 2026\n---\n\nAbschnitt 1 – Allgemeines\n\n§ 1 Zweck\nDieses Gesetz regelt Leuchtfeuer.\n\n"
  . "§ 2 Zeit\nEin Feuer brennt von Sonnenuntergang bis Sonnenaufgang.\n\n§ 3 Wache\nJedes Feuer ist zu bewachen.\n\n§ 4 Schluss\nEnde.\n";
$dir->child('quellen')->mkpath;
$dir->child( 'quellen', 'lfg.txt' )->spew_raw( Encode::encode( 'UTF-8', $law ) );
$dir->child( 'quellen', 'unused.txt' )->spew_raw("Titel: x\n---\n\n§ 1 A\nx\n");

sub write_suite {
  my ( $range ) = @_;
  $dir->child('suite.pl')->spew_utf8( <<"P" );
use Langertha::Holmgang;
use utf8;

suite 'law' => sub {
  title   'Excerpts';
  version 1;
  topic   'probe';
  tool answer => (
    description => 'Give the answer.',
    parameters  => { type => 'object', required => ['verdict'],
                     properties => { verdict => { type => 'string', enum => [qw( ja nein )] } } },
    handlers    => [ handler apply => [ { set => 'answer', value => '{verdict}' } ], output => 'ok' ],
  );
  for my \$c ( [ list => 0 ], [ single => 1 ] ) {
    case \$c->[0] => sub {
      title 'Does the beacon burn at night?';
      ask \$c->[1]
        ? excerpt( 'quellen/lfg.txt', $range )
        : [ "Read the statute.\\n\\n", excerpt( 'quellen/lfg.txt', $range ), "\\n\\nDoes it burn at night? Answer with the tool." ];
      world answer => 'nein';
      rule answered => at 'answer', equals => 'ja';
      solution call answer => { verdict => 'ja' };
      alternative twice => call( answer => { verdict => 'ja' } ), call( answer => { verdict => 'ja' } );
      wrong 'no' => call answer => { verdict => 'nein' };
    };
  }
};
P
}

my $L = Langertha::Holmgang::Loader->new;

write_suite(q{from => '§ 2', to => '§ 7'});
my $err = eval { $L->load("$dir"); 1 } ? undef : Langertha::Holmgang::Error->caught($@) // $@;
ok( ref $err && $err->field eq 'suite.pl: case list: messages[0].content[1].auszug.bis' && $err->reason =~ /§ 7 is not in/,
  'a bad range is refused with the case and the field' ) or diag( $err // 'loaded' );

write_suite(q{from => '§ 2', to => '§ 3'});
my $suite = $L->load("$dir");
my %sent  = map { $_->id => $_->prompt_messages->[0]{content} } @{ $suite->cases };
like( $sent{list}, qr/\ARead the statute\.\n\nLeuchtfeuergesetz \(LfG\)\nAuszug: § 2 bis § 3\nStand: erfunden 2026\n\n§ 2 Zeit\n.*§ 3 Wache\nJedes Feuer ist zu bewachen\.\n\n\nDoes it burn/s,
  'list: the excerpt set in between the texts' );
unlike( $sent{list}, qr/§ 1 Zweck|§ 4 Schluss/, '... only the range' );
like( $sent{single}, qr/\ALeuchtfeuergesetz \(LfG\)\nAuszug: § 2 bis § 3\n/, 'single: the excerpt alone' );
ok( !grep( { ref $_ || /datei|auszug:/ } values %sent ), 'the model is sent text, never the spec' );

my $out = path( $L->export( "$dir", $tmp->child('out') ) );
is_deeply( [ sort map { $_->relative($out)->stringify } grep { -f $_ } $out->children, $out->child('cases')->children, $out->child('quellen')->children ],
  [ 'cases/list.yaml', 'cases/single.yaml', 'quellen/lfg.txt', 'suite.yaml' ], 'export: the cases and the fixture an excerpt reads, nothing else' );
is( $out->child( 'quellen', 'lfg.txt' )->slurp_raw, $dir->child( 'quellen', 'lfg.txt' )->slurp_raw, '... the fixture byte for byte' );
my $yaml = YAML::XS::Load( $out->child( 'cases', 'single.yaml' )->slurp_raw );
is_deeply( $yaml->{messages}[0]{content}, { auszug => { datei => 'quellen/lfg.txt', von => '§ 2', bis => '§ 3' } }, '... the part written as it is' );
my $back = $L->load("$out");
is( $back->digest, $suite->digest, 'the export loads back with the same digest' );
is_deeply( { map { $_->id => $_->prompt_messages->[0]{content} } @{ $back->cases } }, \%sent, '... and the same text sent' );

done_testing;
