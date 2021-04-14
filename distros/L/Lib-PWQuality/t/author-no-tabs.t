
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
    'lib/Lib/PWQuality.pm',
    'lib/Lib/PWQuality/Return.pod',
    'lib/Lib/PWQuality/Settings.pod',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/check.t',
    't/conf/pwquality.conf',
    't/generate.t',
    't/read_config.t',
    't/settings.t'
);

notabs_ok($_) foreach @files;
done_testing;
