
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
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-no404s.t',
    't/author-pod-syntax.t',
    't/author-synopsis.t',
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
    't/release-kwalitee.t'
);

notabs_ok($_) foreach @files;
done_testing;
