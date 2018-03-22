
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
    'lib/Lingua/EN/Opinion.pm',
    'lib/Lingua/EN/Opinion/Emotion.pm',
    'lib/Lingua/EN/Opinion/Emotion.pod',
    'lib/Lingua/EN/Opinion/Negative.pm',
    'lib/Lingua/EN/Opinion/Positive.pm',
    't/00-compile.t',
    't/01-methods.t',
    't/test.txt'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
