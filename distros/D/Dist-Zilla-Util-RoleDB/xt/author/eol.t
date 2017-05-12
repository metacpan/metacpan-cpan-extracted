use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Util/RoleDB.pm',
    'lib/Dist/Zilla/Util/RoleDB/Entry.pm',
    'lib/Dist/Zilla/Util/RoleDB/Entry/Phase.pm',
    'lib/Dist/Zilla/Util/RoleDB/Items.pm',
    'lib/Dist/Zilla/Util/RoleDB/Items/Core.pm',
    'lib/Dist/Zilla/Util/RoleDB/Items/ThirdParty.pm',
    't/00-compile/lib_Dist_Zilla_Util_RoleDB_Entry_Phase_pm.t',
    't/00-compile/lib_Dist_Zilla_Util_RoleDB_Entry_pm.t',
    't/00-compile/lib_Dist_Zilla_Util_RoleDB_Items_Core_pm.t',
    't/00-compile/lib_Dist_Zilla_Util_RoleDB_Items_ThirdParty_pm.t',
    't/00-compile/lib_Dist_Zilla_Util_RoleDB_Items_pm.t',
    't/00-compile/lib_Dist_Zilla_Util_RoleDB_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/phases.t',
    't/roles.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
