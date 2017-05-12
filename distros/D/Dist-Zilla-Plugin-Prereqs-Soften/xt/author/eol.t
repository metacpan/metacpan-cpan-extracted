use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/Prereqs/Soften.pm',
    't/00-compile/lib_Dist_Zilla_Plugin_Prereqs_Soften_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-to_relationship-suggested.t',
    't/03-copy_to-develop-requires.t',
    't/04-modules_from_features.t',
    't/05-to_relationship-none.t',
    't/06-bad-copy_to.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
