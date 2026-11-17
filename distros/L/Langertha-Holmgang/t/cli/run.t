#!/usr/bin/env perl
# holmgang run against network-free targets: the replay and text-only mocks and a
# scripted Langertha::Engine::Virtual; the report it writes. No key, no network,
# invented suites only (ADR 0003).
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Path::Tiny qw( path );
use JSON::MaybeXS ();

use Holmgang::CLI qw( cli good_suite threshold_suite );
use Langertha::Holmgang::Report;

my $root  = Path::Tiny->tempdir;
my $good  = good_suite( id => 'run-fan', root => $root );
my $gated = threshold_suite( id => 'run-gated', root => $root );
my $out_dir = Path::Tiny->tempdir;

sub only_run { my ( $file ) = @_; my $r = Langertha::Holmgang::Report->read($file); return $r->runs->[0] }

{
  my $file = $out_dir->child('replay.json');
  my ( $code, $out, $err ) = cli( run => '--suite', $good, '--target', 'mock-solution', '--repeat', 2, '--report', "$file" );
  is( $code, 0, 'mock-solution: every verdict ok, exit 0' ) or diag $err;
  like( $out, qr/^run-fan c1 #1 passed$/m, '... a line per case and repetition' );
  like( $out, qr/^run-fan c1 #2 passed$/m, '... the second repetition too' );
  like( $out, qr/^Comparison by topic/m, '... then the evaluation' );
  like( $out, qr/^report: \Q$file\E$/m, '... and where the report went' );
  ok( -f $file, 'the report is written' );
  my $run = only_run($file);
  is_deeply( $run->{target}, { label => 'mock-solution', engine => 'Virtual', model => undef, url => undef },
    '... target of the replay mock' );
  is_deeply( $run->{variant}, { name => 'default', settings => {} }, '... the default variant' );
  is( $run->{suite}{id}, 'run-fan', '... the suite' );
  is( $run->{repeat}, 2, '... repeat as asked' );
  is( $run->{status}, 'complete', '... complete' );
  is_deeply( [ map { $_->{status} } @{ $run->{cases}[0]{repetitions} } ], [qw( passed passed )], '... both repetitions passed' );
}

{
  my $file = $out_dir->child('text.json');
  my ( $code, $out ) = cli( run => '--suite', $good, '--suite', $gated, '--target', 'mock-text', '--report', "$file" );
  is( $code, 1, 'mock-text against a suite with a threshold: a verdict not ok, exit 1' );
  like( $out, qr/^run-fan c1 #1 failed$/m, '... text only fails' );
  like( $out, qr/run-gated .*NOT PASSED/, '... the gated suite misses its threshold' );
  my $r = Langertha::Holmgang::Report->read("$file");
  is_deeply( [ map { $_->{suite}{id} } @{ $r->runs } ], [qw( run-fan run-gated )], '... one run per suite, in order' );
}

{
  # a real engine class with constructor options, network-free: a scripted Virtual
  my $file = $out_dir->child('virtual.json');
  my ( $code, $out, $err ) = cli( run => '--suite', $good, '--target', 'Virtual', '--model', 'vm-1',
    '--option', 'script=[{"tool_calls":[["fan_set",{"level":"high"}]]},{"answer":"done"}]',
    '--variant', 'max_tokens=123', '--variant', 'enable_thinking=off', '--report', "$file" );
  is( $code, 0, 'an engine by name with --model and --option: exit 0' ) or diag $err;
  like( $out, qr/^run-fan c1 #1 passed$/m, '... the scripted engine passes the case' );
  my $run = only_run($file);
  is( $run->{target}{engine}, 'Virtual', '... engine name without the namespace' );
  is( $run->{target}{model}, 'vm-1', '... model from --model' );
  is( $run->{target}{label}, 'vm-1', '... label defaults to the model' );
  # the settings checked and normalised (k15): on/off becomes a JSON boolean
  is( $run->{variant}{name}, 'enable_thinking=false,max_tokens=123', '... the variant named from the sorted, normalised pairs' );
  is( $run->{variant}{settings}{max_tokens}, 123, '... numbers as numbers' );
  ok( JSON::MaybeXS::is_bool( $run->{variant}{settings}{enable_thinking} ) && !$run->{variant}{settings}{enable_thinking},
    '... enable_thinking=off as JSON false' );
  is_deeply( [ sort keys %{ $run->{variant}{settings} } ], [qw( enable_thinking max_tokens )], '... nothing else' );
}

{
  # a program error inside a case aborts that suite's run; the report still goes out
  my $file = $out_dir->child('broken.json');
  my ( $code, $out ) = cli( run => '--suite', $good, '--target', 'Holmgang::BrokenEngine', '--label', 'broken',
    '--option', 'script=[{"tool_calls":[["fan_set",{"level":"high"}]]},{"answer":"done"}]', '--report', "$file" );
  is( $code, 2, 'an aborted run: exit 2' );
  like( $out, qr/^run-fan c1 #1 aborted: tool results broke$/m, '... said, scrubbed of location and path' );
  my $run = only_run($file);
  is( $run->{status}, 'aborted', '... the run is aborted in the report' );
  is( $run->{error}, 'tool results broke', '... with the scrubbed error' );
  unlike( path($file)->slurp_utf8, qr{/home/someone}, '... no host path in the report' );
}

{
  my ( $code, undef, $err ) = cli( run => '--suite', $good );
  is( $code, 2, 'no --target: exit 2' );
  like( $err, qr/run needs --target/, '... there is no default target' );

  ( $code, undef, $err ) = cli( run => '--suite', $good, '--target', 'Virtual', '--option', 'api_key=sk-test-0123456789abcdef0123' );
  is( $code, 2, '--option api_key: exit 2' );
  like( $err, qr/api_key is refused/, '... refused, the key belongs in the environment' );
  unlike( $err, qr/sk-test/, '... and not echoed' );

  ( $code, undef, $err ) = cli( run => '--suite', $good, '--target', 'NoSuchEngineAnywhere' );
  is( $code, 2, 'an engine that does not exist: exit 2' );
  like( $err, qr/target NoSuchEngineAnywhere does not build/, '... said' );
  unlike( $err, qr{ at \S+ line \d+}, '... without a Perl location' );

  is( ( cli( run => '--suite', $good, '--target', 'mock-solution', '--model', 'x' ) )[0], 2, '--model with a mock target: exit 2' );
  is( ( cli( run => '--suite', $good, '--target', 'mock-solution', '--repeat', 0 ) )[0], 2, '--repeat 0: exit 2' );
  is( ( cli( run => '--suite', $good, '--target', 'mock-solution', '--variant', 'no-equals' ) )[0], 2, 'a --variant without = : exit 2' );
  is( ( cli( run => '--target', 'mock-solution' ) )[0], 2, 'no --suite: exit 2' );
  is( ( cli( run => '--suite', "$root/none", '--target', 'mock-solution' ) )[0], 2, 'a --suite that is no suite: exit 2' );
}

done_testing;
