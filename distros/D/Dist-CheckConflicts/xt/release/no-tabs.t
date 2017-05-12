use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/CheckConflicts.pm'
);

notabs_ok($_) foreach @files;
done_testing;
