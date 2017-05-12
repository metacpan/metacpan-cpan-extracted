
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MIDI/Simple/Drummer.pm',
    'lib/MIDI/Simple/Drummer/Euclidean.pm',
    'lib/MIDI/Simple/Drummer/Jazz.pm',
    'lib/MIDI/Simple/Drummer/Rock.pm',
    'lib/MIDI/Simple/Drummer/Rudiments.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-Drummer.t',
    't/02-Rock.t',
    't/03-Jazz.t',
    't/04-Rudiments.t',
    't/05-Euclidean.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t',
    't/release-synopsis.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
