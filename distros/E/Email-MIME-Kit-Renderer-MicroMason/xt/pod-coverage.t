#!/usr/bin/env perl

# Ensure pod coverage in your distribution
use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}

my @MODULES = ( 'Test::Pod::Coverage 1.08', "Pod::Coverage::TrustPod 0.10" );

# Don't run tests during end-user installs
use Test::More;

# plan( skip_all => 'Author tests not required for installation' )
#   unless ( $ENV{RELEASE_TESTING} );

# Load the testing modules
foreach my $MODULE (@MODULES) {
    eval "use $MODULE";
    if ($@) {
        $ENV{RELEASE_TESTING}
          ? die("Failed to load required release-testing module $MODULE")
          : plan( skip_all => "$MODULE not available for testing" );
    }
}

# Skip platform specific modules unless we are on that platform
# Don't require any pod for Moose BUILD subs
pod_coverage_ok( $_,
    { trustme => ['BUILD'], coverage_class => 'Pod::Coverage::TrustPod' } )
  for grep {
    not(   ( $^O ne 'linux' && $_ =~ /Linux$/ )
        or ( $^O ne 'darwin'  && $_ =~ /Mac$/ )
        or ( $^O ne 'freebsd' && $_ =~ /FreeBSD$/ ) )
  } all_modules();

done_testing;

1;
