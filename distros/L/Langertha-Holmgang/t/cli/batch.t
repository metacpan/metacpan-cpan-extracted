#!/usr/bin/env perl
# holmgang run over Langertha::Holmgang::Batch (k15): several variants per
# target, --concurrency, --resume, cancel on a signal. Network-free targets,
# invented suites only (ADR 0003).
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Path::Tiny qw( path );
use JSON::MaybeXS ();

use Holmgang::CLI qw( cli good_suite );
use Holmgang::SuiteDir qw( suite_dir $FAN_CASE );
use Langertha::Holmgang::Report;

my $root = Path::Tiny->tempdir;
my $one  = good_suite( id => 'cli-one', root => $root );
my $two  = suite_dir( id => 'cli-two', root => $root,
  cases => { 'c1.yaml' => $FAN_CASE, 'c2.yaml' => $FAN_CASE =~ s/^id: c1$/id: c2/mr } );
my $out_dir = Path::Tiny->tempdir;

{
  my $file = $out_dir->child('variants.json');
  my ( $code, $out, $err ) = cli( run => '--suite', $one, '--target', 'mock-solution',
    '--variant', 'plain:', '--variant', 'short:max_tokens=50', '--variant', 'short:enable_thinking=on', '--report', "$file" );
  is( $code, 0, 'two named variants: exit 0' ) or diag $err;
  like( $out, qr/^plain cli-one c1 #1 passed$/m, '... a line per variant, case and repetition' );
  like( $out, qr/^short cli-one c1 #1 passed$/m, '... the second variant too' );
  my $r = Langertha::Holmgang::Report->read("$file");
  is_deeply( [ map { $_->{variant}{name} } @{ $r->runs } ], [qw( plain short )], '... one run per variant, in the order named' );
  is( JSON::MaybeXS->new( canonical => 1 )->encode( $r->runs->[1]{variant}{settings} ), '{"enable_thinking":true,"max_tokens":50}',
    '... NAME:K=V pairs gathered under their name, checked and normalised' );
  is_deeply( $r->runs->[0]{variant}{settings}, {}, '... NAME: names a variant without settings' );
}

{
  my ( $code, undef, $err ) = cli( run => '--suite', $one, '--target', 'mock-solution', '--variant', 'hot:temperature=0.7' );
  is( $code, 2, 'a setting the engine would drop: exit 2' );
  like( $err, qr/variant\.temperature: the engine .* takes no temperature/, '... said, with the field' );
  ( $code, undef, $err ) = cli( run => '--suite', $one, '--target', 'mock-solution', '--variant', 'thinking=disabled' );
  is( $code, 2, 'an unknown setting: exit 2' );
  like( $err, qr/variant\.thinking: unknown setting/, '... said' );
  ( $code, undef, $err ) = cli( run => '--suite', $one, '--target', 'mock-solution', '--variant', 'max_tokens=5:' );
  is( $code, 2, 'K=V with a colon in the value: exit 2' );
  like( $err, qr/holmgang: --variant: variant\.max_tokens: a whole number/, '... a pair with a bad value, not a variant named max_tokens=5' );
  ( $code ) = cli( run => '--suite', $one, '--target', 'mock-solution', '--concurrency', 0 );
  is( $code, 2, '--concurrency 0: exit 2' );
  ( $code, undef, $err ) = cli( run => '--suite', $two, '--target', 'mock-solution', '--concurrency', 4, '--repeat', 2 );
  is( $code, 0, '--concurrency 4: exit 0' ) or diag $err;
}

{
  # an interrupted run: the report has c1 #1 and c2 #1 of two repetitions
  my $full = $out_dir->child('full.json');
  is( ( cli( run => '--suite', $two, '--target', 'mock-solution', '--repeat', 2, '--report', "$full" ) )[0], 0, 'a full run' );
  my $data = JSON::MaybeXS->new->decode( $full->slurp_raw );
  my $run = $data->{runs}[0];
  $_->{repetitions} = [ grep { $_->{repetition} == 1 } @{ $_->{repetitions} } ] for @{ $run->{cases} };
  @$run{qw( status error )} = ( 'aborted', 'unfinished: the batch was still running when this report was written' );
  my $cut = $out_dir->child('cut.json');
  $cut->spew_raw( JSON::MaybeXS->new( canonical => 1 )->encode($data) );

  my $file = $out_dir->child('resumed.json');
  my ( $code, $out, $err ) = cli( run => '--suite', $two, '--target', 'mock-solution', '--repeat', 2,
    '--resume', "$cut", '--report', "$file" );
  is( $code, 0, '--resume: exit 0' ) or diag $err;
  is_deeply( [ $out =~ /^(cli-two c\d #\d) \w+$/mg ], [ 'cli-two c1 #2', 'cli-two c2 #2' ], '... only the missing repetitions played' );
  my $r = Langertha::Holmgang::Report->read("$file")->runs->[0];
  is( $r->{status}, 'complete', '... the run complete' );
  is_deeply( [ map { scalar @{ $_->{repetitions} } } @{ $r->{cases} } ], [ 2, 2 ], '... every repetition in the report' );

  ( $code, undef, $err ) = cli( run => '--suite', $two, '--target', 'mock-solution', '--repeat', 3, '--resume', "$cut" );
  is( $code, 2, 'a resume with another repeat: exit 2' );
  like( $err, qr/has repeat 2, this batch 3/, '... said' );
  ( $code, undef, $err ) = cli( run => '--suite', $two, '--target', 'mock-solution', '--resume', $out_dir->child('none.json') );
  is( $code, 2, 'a resume file that does not read: exit 2' );
}

{
  # Ctrl-C while the first case runs: no further case starts, the report is written
  my $file = $out_dir->child('cancelled.json');
  my ( $code, $out, $err ) = cli( run => '--suite', $two, '--target', 'Holmgang::SignalEngine', '--label', 'sig',
    '--option', 'script=[{"tool_calls":[["fan_set",{"level":"high"}]]},{"answer":"done"}]', '--report', "$file" );
  is( $code, 2, 'a cancelled run: exit 2' );
  like( $err, qr/holmgang: INT: cancelling/, '... said on stderr' );
  like( $out, qr/^cli-two c1 #1 passed$/m, '... the case in play finished' );
  unlike( $out, qr/^cli-two c2 /m, '... the next did not start' );
  my $r = Langertha::Holmgang::Report->read("$file")->runs->[0];
  is( $r->{status}, 'cancelled', '... the run cancelled in the report' );
  is_deeply( [ map { scalar @{ $_->{repetitions} } } @{ $r->{cases} } ], [ 1, 0 ], '... with the result it had' );
}

done_testing;
