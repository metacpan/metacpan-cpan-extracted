use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Util/BundleInfo.pm',
    'lib/Dist/Zilla/Util/BundleInfo/Plugin.pm',
    't/00-compile/lib_Dist_Zilla_Util_BundleInfo_Plugin_pm.t',
    't/00-compile/lib_Dist_Zilla_Util_BundleInfo_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/array_nonmvp.t',
    't/array_nonmvp_empty.t',
    't/basic.t',
    't/classic.t',
    't/mvp_alias.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
