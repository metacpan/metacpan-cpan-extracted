#!/usr/bin/perl
use warnings;
use strict;

use lib 'lib';
use Test::More tests => 3;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/Test::More
    XML::Compile
    XML::Compile::Cache
    Geo::GML
   /;

foreach my $package (@show_versions)
{   eval "require $package";

    my $report
      = !$@                    ? "version ". ($package->VERSION || 'unknown')
      : $@ =~ m/^Can't locate/ ? "not installed"
      : "reports error";

    warn "$package $report\n";
}

use_ok('Geo::ISO19139::Util');
use_ok('Geo::ISO19139');
use_ok('Geo::ISO19139::2005');
