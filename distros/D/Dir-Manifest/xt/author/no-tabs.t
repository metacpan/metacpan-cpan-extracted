use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dir/Manifest.pm',
    'lib/Dir/Manifest/Key.pm',
    'lib/Dir/Manifest/Slurp.pm',
    't/00-compile.t',
    't/dir-manifest.t',
    't/slurp.t'
);

notabs_ok($_) foreach @files;
done_testing;
