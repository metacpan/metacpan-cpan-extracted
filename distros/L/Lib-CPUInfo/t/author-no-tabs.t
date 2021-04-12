
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Lib/CPUInfo.pm',
    'lib/Lib/CPUInfo/Cache.pod',
    'lib/Lib/CPUInfo/Cluster.pod',
    'lib/Lib/CPUInfo/Core.pod',
    'lib/Lib/CPUInfo/Package.pod',
    'lib/Lib/CPUInfo/Processor.pod',
    'lib/Lib/CPUInfo/UArchInfo.pod',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/get_count.t',
    't/get_current.t',
    't/get_plural.t',
    't/get_single.t',
    't/get_size.t'
);

notabs_ok($_) foreach @files;
done_testing;
