use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/loon.pl',
    'lib/Finance/Tax/Aruba.pm',
    'lib/Finance/Tax/Aruba/Income.pm',
    'lib/Finance/Tax/Aruba/Income/2020.pm',
    'lib/Finance/Tax/Aruba/Income/2021.pm',
    'lib/Finance/Tax/Aruba/Income/2023.pm',
    'lib/Finance/Tax/Aruba/Income/2025.pm',
    'lib/Finance/Tax/Aruba/Role/Income/TaxYear.pm',
    't/00-compile.t',
    't/2020.t',
    't/2021.t',
    't/2022.t',
    't/2023.t',
    't/2024.t',
    't/2025.t',
    't/lib/Test/TestFinanceAW.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
