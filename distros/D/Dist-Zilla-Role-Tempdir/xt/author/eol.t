use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Role/Tempdir.pm',
    'lib/Dist/Zilla/Tempdir/Dir.pm',
    'lib/Dist/Zilla/Tempdir/Item.pm',
    'lib/Dist/Zilla/Tempdir/Item/State.pm',
    't/00-compile/lib_Dist_Zilla_Role_Tempdir_pm.t',
    't/00-compile/lib_Dist_Zilla_Tempdir_Dir_pm.t',
    't/00-compile/lib_Dist_Zilla_Tempdir_Item_State_pm.t',
    't/00-compile/lib_Dist_Zilla_Tempdir_Item_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-poc.t',
    't/02-poc-oo.t',
    't/03-from-code.t',
    't/fake/dist.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
