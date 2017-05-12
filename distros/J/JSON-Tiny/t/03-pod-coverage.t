use strict;
use warnings;
use Test::More;

if( $ENV{RELEASE_TESTING} ) {
  eval 'use Test::Pod::Coverage 1.00'; ## no critic (eval)
  if( $@ ) {
    plan skip_all => 'Test::Pod::Coverage 1.00 required for this test.';
  }
  else { plan tests => 1; }
}
else { plan skip_all => 'Author Test: Set $ENV{RELEASE_TESTING} to run.'; }

pod_coverage_ok( 'JSON::Tiny', {also_private => [ qw/encode decode error new/ ]}
);
