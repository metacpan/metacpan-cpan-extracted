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
    't/api.t',
    't/assert_result.t',
    't/callback/exceptions.t',
    't/constants.t',
    't/lifetime/construction.t',
    't/lifetime/mconstraints.t',
    't/lifetime/objective.t',
    't/lifetime/preconditioner.t',
    't/lifetime/scalar_constraints.t',
    't/lorentzfit.t',
    't/object-safety.t',
    't/perl.t'
);

notabs_ok($_) foreach @files;
done_testing;
