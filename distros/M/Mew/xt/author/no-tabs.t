use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Mew.pm',
    'lib/ew.pm',
    't/00-compile.t',
    't/01-mew.t',
    't/02-optional.t',
    't/Class1.pm',
    't/Class2.pm'
);

notabs_ok($_) foreach @files;
done_testing;
