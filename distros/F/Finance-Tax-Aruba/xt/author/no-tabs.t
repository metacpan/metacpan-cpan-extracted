use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/loon.pl',
    'lib/Finance/Tax/Aruba.pm',
    'lib/Finance/Tax/Aruba/Income.pm',
    'lib/Finance/Tax/Aruba/Income/2020.pm',
    'lib/Finance/Tax/Aruba/Income/2021.pm',
    'lib/Finance/Tax/Aruba/Role/Income/TaxYear.pm',
    't/00-compile.t',
    't/01-2020.t',
    't/02-2021.t',
    't/03-2022.t'
);

notabs_ok($_) foreach @files;
done_testing;
