use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Exception/Class.pm',
    'lib/Exception/Class/Base.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/caught.t',
    't/context.t',
    't/ecb-standalone.t',
    't/ignore.t'
);

notabs_ok($_) foreach @files;
done_testing;
