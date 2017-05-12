
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.07

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Finance/Bank/FI/ReferenceNumber.pm',
    't/00-compile.t',
    't/00-load.t',
    't/author-critic.t',
    't/author/pod.t',
    't/lib/Makefile.PL',
    't/lib/TestApp.pm',
    't/lib/TestApp/Controller/Root.pm',
    't/lib/script/testapp_server.pl',
    't/lib/script/testapp_test.pl',
    't/live-test.t',
    't/release-check-changes.t',
    't/release-kwalitee.t',
    't/release-no-tabs.t',
    't/release-pod-syntax.t'
);

notabs_ok($_) foreach @files;
done_testing;
