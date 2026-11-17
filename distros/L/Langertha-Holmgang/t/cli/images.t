#!/usr/bin/env perl
# holmgang run over a suite with images (k27): the vision pre-check runs once
# per suite before its cases; a blind target gets no_vision for every case with
# images and no request for them, a case without images still runs; the
# replay mock passes twice identically; the report carries no image content.
# Network-free, invented suites only (ADR 0003).
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Path::Tiny qw( path );

use Holmgang::CLI qw( cli );
use Holmgang::Images qw( image_suite );
use Holmgang::SuiteDir qw( $FAN_CASE );
use Langertha::Holmgang::Report;

my $root = Path::Tiny->tempdir;
my $out  = Path::Tiny->tempdir;
my $dir  = image_suite( id => 'run-img', root => $root, more => { 'c2.yaml' => $FAN_CASE =~ s/c1/c2/r } );

my @reports;
for my $n ( 1 .. 2 ) {
  my $file = $out->child("replay$n.json");
  my ( $code, $stdout, $err ) = cli( run => '--suite', $dir, '--target', 'mock-solution', '--report', "$file" );
  is( $code, 0, "mock-solution, run $n: exit 0" ) or diag $err;
  like( $stdout, qr/^run-img vision check: not ruled out -- sight test unmeasured: the target reports no input tokens$/m,
    '... the vision check: the mock reports no tokens, so it is let through' );
  like( $stdout, qr/^run-img c1 #1 passed$/m, '... the case with an image passes' );
  like( $stdout, qr/^run-img c2 #1 passed$/m, '... the case without' );
  my $json = $file->slurp_raw;
  unlike( $json, qr/base64|data:image|iVBOR/, '... the report holds no image content' );
  push @reports, Langertha::Holmgang::Report->read("$file")->runs->[0];
}
my @strip = map {
  my $run = $_;
  [ map { [ map { my %r = %$_; delete $r{duration_ms}; delete $r{turns}; \%r } @{ $_->{repetitions} } ] } @{ $run->{cases} } ];
} @reports;
is_deeply( $strip[0], $strip[1], 'two mock runs: identical results' );

{
  my $file = $out->child('blind.json');
  my ( $code, $stdout, $err ) = cli( run => '--suite', $dir, '--target', 'Virtual',
    '--option', 'script=[{"tool_calls":[["fan_set",{"level":"high"}]]},{"answer":"done"}]', '--report', "$file" );
  like( $stdout, qr/^run-img vision check: no_vision -- the engine Langertha::Engine::Virtual takes no image/m,
    'a target without vision: the pre-check says no_vision' );
  like( $stdout, qr/^run-img c1 #1 no_vision$/m, '... the case with an image: no_vision' );
  like( $stdout, qr/^run-img c2 #1 passed$/m, '... the case without still runs' );
  my $run = Langertha::Holmgang::Report->read("$file")->runs->[0];
  my ($c1) = grep { $_->{case_id} eq 'c1' } @{ $run->{cases} };
  is( $c1->{repetitions}[0]{status}, 'no_vision', '... in the report' );
  is_deeply( $c1->{repetitions}[0]{turns}, [], '... without a turn' );
  like( $c1->{repetitions}[0]{error}, qr/takes no image/, '... the reason as the error' );
  is( $code, 0, '... measured on the other case, no verdict missed: exit 0' ) or diag $err;
}

done_testing;
