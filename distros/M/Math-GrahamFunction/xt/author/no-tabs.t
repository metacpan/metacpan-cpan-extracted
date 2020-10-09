use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Math/GrahamFunction.pm',
    'lib/Math/GrahamFunction/Object.pm',
    'lib/Math/GrahamFunction/SqFacts.pm',
    'lib/Math/GrahamFunction/SqFacts/Dipole.pm',
    't/00-compile.t',
    't/01-results.t',
    't/01-results.t~'
);

notabs_ok($_) foreach @files;
done_testing;
