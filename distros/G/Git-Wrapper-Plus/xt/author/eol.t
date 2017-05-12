use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Git/Wrapper/Plus.pm',
    'lib/Git/Wrapper/Plus/Branches.pm',
    'lib/Git/Wrapper/Plus/Ref.pm',
    'lib/Git/Wrapper/Plus/Ref/Branch.pm',
    'lib/Git/Wrapper/Plus/Ref/Tag.pm',
    'lib/Git/Wrapper/Plus/Refs.pm',
    'lib/Git/Wrapper/Plus/Support.pm',
    'lib/Git/Wrapper/Plus/Support/Arguments.pm',
    'lib/Git/Wrapper/Plus/Support/Behaviors.pm',
    'lib/Git/Wrapper/Plus/Support/Commands.pm',
    'lib/Git/Wrapper/Plus/Support/Range.pm',
    'lib/Git/Wrapper/Plus/Support/RangeDictionary.pm',
    'lib/Git/Wrapper/Plus/Support/RangeSet.pm',
    'lib/Git/Wrapper/Plus/Tags.pm',
    'lib/Git/Wrapper/Plus/Tester.pm',
    'lib/Git/Wrapper/Plus/Util.pm',
    'lib/Git/Wrapper/Plus/Versions.pm',
    't/00-compile/lib_Git_Wrapper_Plus_Branches_pm.t',
    't/00-compile/lib_Git_Wrapper_Plus_Ref_Branch_pm.t',
    't/00-compile/lib_Git_Wrapper_Plus_Ref_Tag_pm.t',
    't/00-compile/lib_Git_Wrapper_Plus_Ref_pm.t',
    't/00-compile/lib_Git_Wrapper_Plus_Refs_pm.t',
    't/00-compile/lib_Git_Wrapper_Plus_Support_Arguments_pm.t',
    't/00-compile/lib_Git_Wrapper_Plus_Support_Behaviors_pm.t',
    't/00-compile/lib_Git_Wrapper_Plus_Support_Commands_pm.t',
    't/00-compile/lib_Git_Wrapper_Plus_Support_RangeDictionary_pm.t',
    't/00-compile/lib_Git_Wrapper_Plus_Support_RangeSet_pm.t',
    't/00-compile/lib_Git_Wrapper_Plus_Support_Range_pm.t',
    't/00-compile/lib_Git_Wrapper_Plus_Support_pm.t',
    't/00-compile/lib_Git_Wrapper_Plus_Tags_pm.t',
    't/00-compile/lib_Git_Wrapper_Plus_Tester_pm.t',
    't/00-compile/lib_Git_Wrapper_Plus_Util_pm.t',
    't/00-compile/lib_Git_Wrapper_Plus_Versions_pm.t',
    't/00-compile/lib_Git_Wrapper_Plus_pm.t',
    't/00-report-git-support.t',
    't/00-report-git-version.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/branches/basic.t',
    't/plus/basic.t',
    't/plus/path-class-constructor.t',
    't/plus/path-tiny-constructor.t',
    't/refs/basic_branches.t',
    't/refs/basic_tags.t',
    't/tags/basic.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
