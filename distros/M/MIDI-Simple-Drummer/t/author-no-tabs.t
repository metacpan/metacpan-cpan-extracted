
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
    'lib/MIDI/Simple/Drummer.pm',
    'lib/MIDI/Simple/Drummer/Euclidean.pm',
    'lib/MIDI/Simple/Drummer/Jazz.pm',
    'lib/MIDI/Simple/Drummer/Rock.pm',
    'lib/MIDI/Simple/Drummer/Rudiments.pm',
    't/00-compile.t',
    't/01-Drummer.t',
    't/02-Rock.t',
    't/03-Jazz.t',
    't/04-Rudiments.t',
    't/05-Euclidean.t'
);

notabs_ok($_) foreach @files;
done_testing;
