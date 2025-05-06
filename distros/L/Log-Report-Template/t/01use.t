#!/usr/bin/env perl

use warnings;
use strict;

use lib 'lib';
use Test::More;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/Test::More
    Log::Report
    Log::Report::Optional
    Log::Report::Lexicon
    String::Print
	Template
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

require_ok('Log::Report::Template');
require_ok('Log::Report::Template::Extract');
require_ok('Log::Report::Template::Textdomain');

done_testing;
