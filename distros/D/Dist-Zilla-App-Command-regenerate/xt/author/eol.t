use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/App/Command/regenerate.pm',
    'lib/Dist/Zilla/Plugin/Regenerate.pm',
    'lib/Dist/Zilla/Plugin/Regenerate/AfterReleasers.pm',
    'lib/Dist/Zilla/Role/Regenerator.pm',
    't/00-compile/lib_Dist_Zilla_App_Command_regenerate_pm.t',
    't/00-compile/lib_Dist_Zilla_Plugin_Regenerate_AfterReleasers_pm.t',
    't/00-compile/lib_Dist_Zilla_Plugin_Regenerate_pm.t',
    't/00-compile/lib_Dist_Zilla_Role_Regenerator_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/plugin/afterreleasers.t',
    't/plugin/regenerate.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
