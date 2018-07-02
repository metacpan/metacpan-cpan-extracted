
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
    'lib/IP/Random.pm',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-Basic.t',
    't/02-Benchmark.t',
    't/03-random.t',
    't/04-invalid-character.t',
    't/05-invalid-tag.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/author-test-version.t',
    't/data/perlcriticrc',
    't/release-kwalitee.t',
    't/release-trailing-space.t',
    't/release-unused-vars.t'
);

notabs_ok($_) foreach @files;
done_testing;
