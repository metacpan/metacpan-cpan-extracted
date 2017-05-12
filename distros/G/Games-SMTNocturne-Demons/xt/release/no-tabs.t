use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.07

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/smt',
    'lib/Games/SMTNocturne/Demons.pm',
    'lib/Games/SMTNocturne/Demons/Demon.pm',
    'lib/Games/SMTNocturne/Demons/Fusion.pm',
    'lib/Games/SMTNocturne/Demons/FusionChart.pm',
    't/00-compile.t',
    't/basic.t',
    't/lib/Test/Games/SMTNocturne/Demons.pm',
    't/special.t',
    't/symmetric.t'
);

notabs_ok($_) foreach @files;
done_testing;
