#!perl

use strict;
use warnings;

use Test::More;
use Class::Load qw(try_load_class);

plan skip_all => "set RELEASE_TESTING to test POD" unless $ENV{RELEASE_TESTING};

sub Pod::Coverage::TRACE_ALL () { 1 }

my $min_tpc_version = 1.04;
try_load_class( "Test::Pod::Coverage", { -version => $min_tpc_version } )
  or plan skip_all =>
  "Test::Pod::Coverage $min_tpc_version required for testing POD coverage";

Test::Pod::Coverage::all_pod_coverage_ok();
