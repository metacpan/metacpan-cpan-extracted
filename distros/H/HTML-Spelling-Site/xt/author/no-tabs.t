use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

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

notabs_ok($_) foreach @files;
done_testing;
