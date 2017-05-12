use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/App/Command/bakeini.pm',
    't/00-compile/lib_Dist_Zilla_App_Command_bakeini_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-show-abstract.t',
    't/03-nodistinimeta.t',
    't/04-comment-control.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
