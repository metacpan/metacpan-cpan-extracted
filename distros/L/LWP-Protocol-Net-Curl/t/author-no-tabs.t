
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/LWP/Protocol/Net/Curl.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-simple.t',
    't/02-ua.t',
    't/03-file.t',
    't/04-callback.t',
    't/05-live.t',
    't/06-edge.t',
    't/07-min-libcurl.t',
    't/08-curlopt-fwd.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-minimum-version.t',
    't/release-mojibake.t',
    't/release-pod-coverage.t',
    't/release-pod-linkcheck.t',
    't/release-pod-syntax.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/release-test-version.t',
    't/release-unused-vars.t'
);

notabs_ok($_) foreach @files;
done_testing;
