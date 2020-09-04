use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/IO/ReStoreFH.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/breakage.t',
    't/fd.t',
    't/iface.t',
    't/lib/My/Test.pm',
    't/std.t'
);

notabs_ok($_) foreach @files;
done_testing;
