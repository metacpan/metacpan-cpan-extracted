use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Util/ConfigDumper.pm',
    't/00-compile/lib_Dist_Zilla_Util_ConfigDumper_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/attr_lazy.t',
    't/bang_on_ref.t',
    't/basic.t',
    't/basic_inherit_attr.t',
    't/basic_role_attr.t',
    't/callback.t',
    't/failattr.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
