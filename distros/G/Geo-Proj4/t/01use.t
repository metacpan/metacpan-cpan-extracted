#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;
use lib 'lib';

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/Scalar::Util
   /;

foreach my $package (@show_versions)
{   eval "require $package";

    no strict 'refs';
    my $report
      = !$@    ? "version ". (${"$package\::VERSION"} || 'unknown')
      : $@ =~ m/^Can't locate/ ? "not installed"
      : "reports error";

    warn "$package $report\n";
}

require_ok 'Geo::Proj4';

my $libv = Geo::Proj4->libVersion;
diag "PROJ$libv";

done_testing;
