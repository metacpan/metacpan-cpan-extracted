
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Plugin/TravisCI/StatusBadge.pm',
    't/00-compile.t',
    't/01-basic.t',
    't/02-distmeta.t',
    't/03-anyreadme.t',
    't/author-test-eol.t',
    't/lib/Builder.pm',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-no-tabs.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t',
    't/release-test-version.t'
);

notabs_ok($_) foreach @files;
done_testing;
