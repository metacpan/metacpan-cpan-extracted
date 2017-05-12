use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Role/Version/Sanitize.pm',
    't/00-compile/lib_Dist_Zilla_Role_Version_Sanitize_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_3_to_number.t',
    't/02_number_to_v.t',
    't/03_number_to_3.t',
    't/04_force_mantissa5.t',
    't/05_force_mantissa7.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
