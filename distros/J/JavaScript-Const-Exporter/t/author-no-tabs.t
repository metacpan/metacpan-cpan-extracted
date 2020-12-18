
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
    'bin/js-const',
    'lib/JavaScript/Const/Exporter.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/const-exporter.t',
    't/const-fast-exporter.t',
    't/const.t',
    't/fcntl.t',
    't/http-status.t',
    't/lib/Consts1.pm',
    't/lib/Consts2.pm',
    't/lib/Consts3.pm',
    't/release-check-manifest.t',
    't/release-fixme.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t',
    't/script.t'
);

notabs_ok($_) foreach @files;
done_testing;
