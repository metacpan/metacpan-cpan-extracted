
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
    'bin/current-cost-reader',
    'lib/Device/CurrentCost.pm',
    'lib/Device/CurrentCost/Constants.pm',
    'lib/Device/CurrentCost/Message.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-simple.t',
    't/02-serial.t',
    't/03-timeouts.t',
    't/04-history.t',
    't/author-critic.t',
    't/author-test-eol.t',
    't/lib/Device/SerialPort.pm',
    't/lib/POSIX.pm',
    't/log/cc128.complete.history.xml',
    't/log/cc128.incomplete.history.xml',
    't/log/cc128.two.xml',
    't/log/classic.history.xml',
    't/log/classic.reading.xml',
    't/log/classic.too.short.xml',
    't/log/envy.history.xml',
    't/log/envy.reading.xml',
    't/release-common_spelling.t',
    't/release-kwalitee.t',
    't/release-no-tabs.t',
    't/release-pod-coverage.t',
    't/release-pod-linkcheck.t',
    't/release-pod-no404s.t',
    't/release-pod-syntax.t',
    't/release-synopsis.t'
);

notabs_ok($_) foreach @files;
done_testing;
