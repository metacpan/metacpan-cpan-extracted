
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MIDI/Drummer/Tiny.pm',
    'lib/MIDI/Drummer/Tiny/SwingFills.pm',
    'lib/MIDI/Drummer/Tiny/Syncopate.pm',
    'lib/MIDI/Drummer/Tiny/Tutorial/Advanced.pod',
    'lib/MIDI/Drummer/Tiny/Tutorial/Basics.pod',
    'lib/MIDI/Drummer/Tiny/Tutorial/Quickstart.pod',
    'lib/MIDI/Drummer/Tiny/Types.pm',
    't/00-compile.t',
    't/01-methods.t',
    't/verbose_add_fill.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
