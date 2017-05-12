use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.13

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Plugin/Test/CPAN/Meta/JSON.pm',
    't/00-compile.t',
    't/01-prune.t'
);

notabs_ok($_) foreach @files;
done_testing;
