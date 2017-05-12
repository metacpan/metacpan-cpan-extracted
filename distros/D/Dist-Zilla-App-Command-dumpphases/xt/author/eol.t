use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/App/Command/dumpphases.pm',
    'lib/Dist/Zilla/dumpphases/Role/Theme.pm',
    'lib/Dist/Zilla/dumpphases/Role/Theme/SimpleColor.pm',
    'lib/Dist/Zilla/dumpphases/Theme/basic/blue.pm',
    'lib/Dist/Zilla/dumpphases/Theme/basic/green.pm',
    'lib/Dist/Zilla/dumpphases/Theme/basic/plain.pm',
    'lib/Dist/Zilla/dumpphases/Theme/basic/red.pm',
    't/00-compile/lib_Dist_Zilla_App_Command_dumpphases_pm.t',
    't/00-compile/lib_Dist_Zilla_dumpphases_Role_Theme_SimpleColor_pm.t',
    't/00-compile/lib_Dist_Zilla_dumpphases_Role_Theme_pm.t',
    't/00-compile/lib_Dist_Zilla_dumpphases_Theme_basic_blue_pm.t',
    't/00-compile/lib_Dist_Zilla_dumpphases_Theme_basic_green_pm.t',
    't/00-compile/lib_Dist_Zilla_dumpphases_Theme_basic_plain_pm.t',
    't/00-compile/lib_Dist_Zilla_dumpphases_Theme_basic_red_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-noparam.t',
    't/02-bad-theme.t',
    't/03-green-theme.t',
    't/04-red-theme.t',
    't/05-plain-theme.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
