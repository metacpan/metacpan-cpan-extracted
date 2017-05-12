#!/usr/bin/env perl
use warnings;
use strict;

use lib 'lib';
use Test::More tests => 2;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/Geo::EOP
    Test::More
    XML::Compile
    XML::Compile::Cache
    Geo::GML
    Geo::ISO19139
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

use_ok('Geo::EOP::Util');
use_ok('Geo::EOP');

# Geo::EOP::Envisat and Geo::EOP::Landsat not tested, because
# they depend on modules which are optional.
