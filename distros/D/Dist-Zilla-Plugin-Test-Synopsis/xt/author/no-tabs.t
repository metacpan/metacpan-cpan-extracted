use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Plugin/SynopsisTests.pm',
    'lib/Dist/Zilla/Plugin/Test/Synopsis.pm',
    't/00-compile.t',
    't/deprecated.t',
    't/everything.t'
);

notabs_ok($_) foreach @files;
done_testing;
