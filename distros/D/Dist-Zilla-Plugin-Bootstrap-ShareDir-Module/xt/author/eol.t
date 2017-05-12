use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/Bootstrap/ShareDir/Module.pm',
    't/00-compile/lib_Dist_Zilla_Plugin_Bootstrap_ShareDir_Module_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-try_built.t',
    't/03-try_built-pass2.t',
    't/04-try_built_nofallback.t',
    't/05-try_built_nofallback-pass2.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
