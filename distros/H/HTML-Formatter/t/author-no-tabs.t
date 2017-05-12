
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print "1..0 # SKIP these tests are for testing by the author\n";
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/HTML/FormatMarkdown.pm',
    'lib/HTML/FormatPS.pm',
    'lib/HTML/FormatRTF.pm',
    'lib/HTML/FormatText.pm',
    'lib/HTML/Formatter.pm'
);

notabs_ok($_) foreach @files;
done_testing;
