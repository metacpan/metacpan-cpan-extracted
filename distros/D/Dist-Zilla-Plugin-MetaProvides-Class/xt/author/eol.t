use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/MetaProvides/Class.pm',
    't/00-compile/lib_Dist_Zilla_Plugin_MetaProvides_Class_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/dz2-provides.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
