use strict;
use warnings;
use Test::More;

if ( not $ENV{RELEASE_TESTING} ) {
  my $msg = 'Author Test: Set $ENV{RELEASE_TESTING} to a true value to run.';
  plan( skip_all => $msg );
}

eval "use Test::Pod::Coverage 1.00"; ## no critic (eval)

plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
  if $@;
  
pod_coverage_ok( 'IO::Prompt::Hooked');

done_testing();
