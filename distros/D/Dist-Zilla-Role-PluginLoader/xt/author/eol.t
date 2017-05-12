use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Role/PluginLoader.pm',
    'lib/Dist/Zilla/Role/PluginLoader/Configurable.pm',
    'lib/Dist/Zilla/Util/PluginLoader.pm',
    't/00-compile/lib_Dist_Zilla_Role_PluginLoader_Configurable_pm.t',
    't/00-compile/lib_Dist_Zilla_Role_PluginLoader_pm.t',
    't/00-compile/lib_Dist_Zilla_Util_PluginLoader_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/loader-basic.t',
    't/loader-configurable.t',
    't/loader-util.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
