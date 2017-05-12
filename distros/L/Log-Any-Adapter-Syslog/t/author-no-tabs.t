
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
    'lib/Log/Any/Adapter/Syslog.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/options/defaults.t',
    't/options/facility.t',
    't/options/minlevel.t',
    't/options/name.t',
    't/options/options.t',
    't/reinit.t',
    't/release-check-changes.t',
    't/release-cpan-changes.t',
    't/release-distmeta.t',
    't/release-has-version.t',
    't/release-meta-json.t',
    't/release-minimum-version.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/release-unused-vars.t',
    't/write-logs.t'
);

notabs_ok($_) foreach @files;
done_testing;
