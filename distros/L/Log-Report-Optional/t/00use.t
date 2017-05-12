#!/usr/bin/env perl
use warnings;
use strict;

use Test::More tests => 3;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/
    Test::More
    String::Print
   /;

warn "Perl $]\n";
foreach my $package (sort @show_versions)
{   eval "require $package";

    my $report
      = !$@                    ? "version ". ($package->VERSION || 'unknown')
      : $@ =~ m/^Can't locate/ ? "not installed"
      : "reports error";

    warn "$package $report\n";
}

use_ok('Log::Report::Util');
use_ok('Log::Report::Minimal');
use_ok('Log::Report::Optional');
