use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Math/NLopt.pm',
    'lib/Math/NLopt/Exception.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/constants.t',
    't/exceptions.t',
    't/lorentzfit.t',
    't/perl.t',
    't/tempdata.t'
);

notabs_ok($_) foreach @files;
done_testing;
