
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
    'lib/Log/Any/Plugin.pm',
    'lib/Log/Any/Plugin/Levels.pm',
    'lib/Log/Any/Plugin/Stringify.pm',
    'lib/Log/Any/Plugin/Util.pm',
    't/00-compile.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/author-synopsis.t',
    't/plugin/levels.t',
    't/plugin/stringify.t',
    't/release-check-changes.t',
    't/release-cpan-changes.t',
    't/release-distmeta.t',
    't/release-meta-json.t',
    't/util.t'
);

notabs_ok($_) foreach @files;
done_testing;
