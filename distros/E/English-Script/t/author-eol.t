
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
    'lib/English/Script.pm',
    't/00-compile.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/author-synopsis.t',
    't/compress.t',
    't/errors.t',
    't/javascript/append.t',
    't/javascript/arrays.t',
    't/javascript/comments.t',
    't/javascript/comparisons.t',
    't/javascript/conditionals.t',
    't/javascript/expressions.t',
    't/javascript/loops.t',
    't/javascript/math.t',
    't/methods.t',
    't/release-kwalitee.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
