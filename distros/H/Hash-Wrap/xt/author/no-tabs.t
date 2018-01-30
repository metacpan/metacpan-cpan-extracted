use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Hash/Wrap.pm',
    'lib/Hash/Wrap/Base.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/api.t',
    't/basic.t',
    't/import.t',
    't/lvalue.t',
    't/lvalue_undef.t',
    't/undef.t'
);

notabs_ok($_) foreach @files;
done_testing;
