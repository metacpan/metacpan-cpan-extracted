use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/HTML/Spelling/Site.pm',
    'lib/HTML/Spelling/Site/Checker.pm',
    'lib/HTML/Spelling/Site/Finder.pm',
    'lib/HTML/Spelling/Site/Whitelist.pm',
    't/00-compile.t',
    't/check-test-functions.t',
    't/data/sites/fully-correct-timestamp/PLACEHOLDER',
    't/data/sites/fully-correct-whitelist/whitelist.txt',
    't/data/sites/fully-correct/index.html',
    't/data/whitelist-with-dup-records.txt',
    't/data/whitelist-with-duplicates.txt',
    't/whitelist.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
