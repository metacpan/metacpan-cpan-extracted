use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Geo/IPfree.pm',
    'lib/Geo/IPfree.pod',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/base.t',
    't/basic-faster.t',
    't/basic-obj.t',
    't/basic.t',
    't/ip-nb.t',
    't/pod.t',
    't/pod_coverage.t',
    't/use.t'
);

notabs_ok($_) foreach @files;
done_testing;
