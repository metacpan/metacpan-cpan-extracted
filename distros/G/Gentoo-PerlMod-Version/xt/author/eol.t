use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/gentoo-perlmod-version.pl',
    'lib/Gentoo/PerlMod/Version.pm',
    'lib/Gentoo/PerlMod/Version/Env.pm',
    'lib/Gentoo/PerlMod/Version/Error.pm',
    't/00-compile/lib_Gentoo_PerlMod_Version_Env_pm.t',
    't/00-compile/lib_Gentoo_PerlMod_Version_Error_pm.t',
    't/00-compile/lib_Gentoo_PerlMod_Version_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_basic.t',
    't/02_vstrings.t',
    't/03_env.t',
    't/04_error.t',
    't/05_throwerror.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
