#!perl -T

use strict;
use warnings;

use Test::More;

# Ensure a recent version of Test::Dist::VersionSync
my $version_min = '1.0.0';
eval "use Test::Dist::VersionSync $version_min";
plan( skip_all => "Test::Dist::VersionSync $version_min required for testing module versions in the distribution." )
	if $@;

Test::Dist::VersionSync::ok_versions();
