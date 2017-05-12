
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Lingua/Word/Parser.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-methods.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t'
);

notabs_ok($_) foreach @files;
done_testing;
