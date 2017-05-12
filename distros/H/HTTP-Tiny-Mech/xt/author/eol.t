use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/HTTP/Tiny/Mech.pm',
    't/00-compile/lib_HTTP_Tiny_Mech_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/get.t',
    't/get/FakeUA.pm',
    't/mech-params.t',
    't/tiny-params.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
