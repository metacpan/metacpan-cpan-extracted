#!/usr/bin/env perl
# --seed ID=N on the command line (k51, ADR 0009 amendment k19/k51): the loader's
# seed override of a DSL suite's generate blocks. Invented suites only (ADR 0003).
# Claims: lint, run and export-yaml build the overridden suite -- other generated
# cases (lint lists other case ids), the overridden suite's digest in the report and
# in the export -- and without --seed the file's seed; a seed that is not ID=N, out
# of 0..4294967295, given twice, or names no DSL suite of the command (a format 2
# suite, a typo) is a usage error, exit 2, before anything runs.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Path::Tiny qw( path );
use Test::More;

use Holmgang::CLI qw( cli good_suite );
use Langertha::Holmgang::Loader;
use Langertha::Holmgang::Report;

my $tmp    = Path::Tiny->tempdir;
my $search = $tmp->child('suites');

# the case ids carry the drawn numbers, so another seed shows in the case list
my $dir = $search->child('seed-sums');
$dir->mkpath;
$dir->child('suite.pl')->spew_utf8(<<'P');
use Langertha::Holmgang;

suite 'seed-sums' => sub {
  title   'Seeded doubles';
  version 1;
  tool submit => (
    description => 'Hand in the number.',
    parameters  => { type => 'object', required => ['value'], properties => { value => { type => 'integer' } } },
    handlers    => [ handler apply => [ { set => 'answer', value => '{value|int}' } ], output => 'ok' ],
  );
  generate seed => 4711, sub {
    my ( $rng ) = @_;
    for my $n ( map { $rng->int( 100, 999 ) } 1 .. 2 ) {
      case "double-$n" => sub {
        title 'Double '.$n;
        world answer => undef;
        ask 'What is twice '.$n.'? Hand it in.';
        rule 'handed in' => at 'answer', equals => 2 * $n;
        rule 'nothing else' => unchanged_except ['answer'];
        solution call submit => { value => 2 * $n };
        alternative 'twice' => call( submit => { value => 1 } ), call( submit => { value => 2 * $n } );
        wrong 'off by one' => call submit => { value => 2 * $n + 1 };
      };
    }
  };
};
P
good_suite( id => 'seed-yaml', root => "$search" );

my $plain  = Langertha::Holmgang::Loader->new->load("$dir");
my $seeded = Langertha::Holmgang::Loader->new( seeds => { 'seed-sums' => 90210 } )->load("$dir");
my @plain_ids  = map { $_->id } @{ $plain->cases };
my @seeded_ids = map { $_->id } @{ $seeded->cases };
isnt( "@seeded_ids", "@plain_ids", 'the override draws other cases (premise)' );

{
  my ( $code, $out, $err ) = cli( 'lint', "$search", '--seed', 'seed-sums=90210' );
  is( $code, 0, 'lint --seed: exit 0' ) or diag $out.$err;
  like( $out, qr/^  ok \Q$_\E$/m, "... lints the overridden case $_" ) for @seeded_ids;
  unlike( $out, qr/^  ok \Q$_\E$/m, "... not the file's case $_" ) for @plain_ids;
  ( $code, $out ) = cli( 'lint', "$dir" );
  like( $out, qr/^  ok \Q$plain_ids[0]\E$/m, 'lint without --seed: the file\'s seed' );
}
{
  my $file = $tmp->child('run.json');
  my ( $code, $out, $err ) = cli( 'run', '--suite', "$dir", '--target', 'mock-solution', '--seed', 'seed-sums=90210',
    '--report', "$file" );
  is( $code, 0, 'run --seed: exit 0' ) or diag $out.$err;
  like( $out, qr/^seed-sums \Q$seeded_ids[0]\E #1 passed$/m, '... runs the overridden cases' );
  is( Langertha::Holmgang::Report->read("$file")->runs->[0]{suite}{digest}, $seeded->digest,
    '... and reports the overridden suite\'s digest' );
}
{
  my $out_dir = $tmp->child('export');
  my ( $code, $out, $err ) = cli( 'export-yaml', "$dir", '--out', "$out_dir", '--seed', 'seed-sums=90210' );
  is( $code, 0, 'export-yaml --seed: exit 0' ) or diag $out.$err;
  is( Langertha::Holmgang::Loader->new->load( $out_dir->child('seed-sums')->stringify )->digest, $seeded->digest,
    '... writes the overridden suite' );
}

for my $bad (
  [ ['seed-yaml=1'],                   qr/no suite in the case DSL/, 'a format 2 suite' ],
  [ ['nope=1'],                        qr/no suite in the case DSL/, 'an unknown id' ],
  [ ['seed-sums=x'],                   qr/expects SUITE-ID=N/,       'not a number' ],
  [ ['seed-sums=-1'],                  qr/expects SUITE-ID=N/,       'negative' ],
  [ ['seed-sums=4294967296'],          qr/0 to 4294967295/,          'too large' ],
  [ [ 'seed-sums=1', 'seed-sums=2' ],  qr/given twice/,              'given twice' ],
) {
  my ( $code, $out, $err ) = cli( 'lint', "$search", map { ( '--seed', $_ ) } @{ $bad->[0] } );
  is( $code, 2, "lint --seed: $bad->[2] is a usage error" );
  like( $err, $bad->[1], '... said so' );
  is( $out, '', '... before anything is linted' );
}
{
  my ( $code, $out, $err ) = cli( 'run', '--suite', "$dir", '--target', 'mock-solution', '--seed', 'other=1' );
  is( $code, 2, 'run --seed for a suite not in the run: exit 2' );
  is( $out, '', '... nothing ran' );
}

done_testing;
