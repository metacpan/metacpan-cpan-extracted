use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/bbo.pl',
    'bin/loon.pl',
    'lib/Finance/Tax/Aruba.pm',
    'lib/Finance/Tax/Aruba/BBO.pm',
    'lib/Finance/Tax/Aruba/BBO/2020.pm',
    'lib/Finance/Tax/Aruba/BBO/2021.pm',
    'lib/Finance/Tax/Aruba/BBO/2022.pm',
    'lib/Finance/Tax/Aruba/BBO/2023.pm',
    'lib/Finance/Tax/Aruba/BBO/2024.pm',
    'lib/Finance/Tax/Aruba/BBO/2025.pm',
    'lib/Finance/Tax/Aruba/Income.pm',
    'lib/Finance/Tax/Aruba/Income/2020.pm',
    'lib/Finance/Tax/Aruba/Income/2021.pm',
    'lib/Finance/Tax/Aruba/Income/2023.pm',
    'lib/Finance/Tax/Aruba/Income/2025.pm',
    'lib/Finance/Tax/Aruba/Income/2026.pm',
    'lib/Finance/Tax/Aruba/Role/BBO/TaxYear.pm',
    'lib/Finance/Tax/Aruba/Role/Income/TaxYear.pm',
    't/00-compile.t',
    't/2020.t',
    't/2021.t',
    't/2022.t',
    't/2023.t',
    't/2024.t',
    't/2025.t',
    't/bbo.t',
    't/lib/Test/TestFinanceAW.pm',
    't/reparatietoeslag.t'
);

notabs_ok($_) foreach @files;
done_testing;
