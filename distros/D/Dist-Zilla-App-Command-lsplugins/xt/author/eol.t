use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/App/Command/lsplugins.pm',
    'lib/Dist/Zilla/lsplugins/Module.pm',
    't/00-compile/lib_Dist_Zilla_App_Command_lsplugins_pm.t',
    't/00-compile/lib_Dist_Zilla_lsplugins_Module_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
