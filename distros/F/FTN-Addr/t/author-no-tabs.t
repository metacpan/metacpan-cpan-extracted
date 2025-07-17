
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
    'lib/FTN/Addr.pm',
    't/00-load.t',
    't/01-examples.t',
    't/02-create.t',
    't/03-sequence.t',
    't/04-clone.t',
    't/05-setters.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t'
);

notabs_ok($_) foreach @files;
done_testing;
