
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
    'lib/HTML/DeferableCSS.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-clean-namespaces.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',
    't/css_files.t',
    't/css_href.t',
    't/defer.t',
    't/etc/css/0.css',
    't/etc/css/1.css',
    't/etc/css/bar.min.css',
    't/etc/css/foo.css',
    't/etc/css/reset.css',
    't/etc/css/reset.min.css',
    't/etc/perlcritic.rc',
    't/inline.t',
    't/release-check-manifest.t',
    't/release-fixme.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t'
);

notabs_ok($_) foreach @files;
done_testing;
