use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Git/PurePerl/Walker.pm',
    'lib/Git/PurePerl/Walker/Method/FirstParent.pm',
    'lib/Git/PurePerl/Walker/Method/FirstParent/FromHEAD.pm',
    'lib/Git/PurePerl/Walker/OnCommit/CallBack.pm',
    'lib/Git/PurePerl/Walker/OnCommit/List.pm',
    'lib/Git/PurePerl/Walker/Role/HasRepo.pm',
    'lib/Git/PurePerl/Walker/Role/Method.pm',
    'lib/Git/PurePerl/Walker/Role/OnCommit.pm',
    'lib/Git/PurePerl/Walker/Types.pm',
    't/00-compile/lib_Git_PurePerl_Walker_Method_FirstParent_FromHEAD_pm.t',
    't/00-compile/lib_Git_PurePerl_Walker_Method_FirstParent_pm.t',
    't/00-compile/lib_Git_PurePerl_Walker_OnCommit_CallBack_pm.t',
    't/00-compile/lib_Git_PurePerl_Walker_OnCommit_List_pm.t',
    't/00-compile/lib_Git_PurePerl_Walker_Role_HasRepo_pm.t',
    't/00-compile/lib_Git_PurePerl_Walker_Role_Method_pm.t',
    't/00-compile/lib_Git_PurePerl_Walker_Role_OnCommit_pm.t',
    't/00-compile/lib_Git_PurePerl_Walker_Types_pm.t',
    't/00-compile/lib_Git_PurePerl_Walker_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_test.t',
    't/0200_firstparent.t',
    't/0201_firstparent_fromhead.t',
    't/03_callback.t',
    't/04_list.t',
    't/tlib/t/util.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
