#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib';
use Test::More tests => 1;

my @show_versions =
 qw/Test::More
    Geo::Shape
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

require_ok('Geo::WKT');
