use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Plugin/Test/UnusedVars.pm',
    'lib/Dist/Zilla/Plugin/UnusedVarsTests.pm',
    't/00-compile.t',
    't/deprecated.t',
    't/file-list.t',
    't/test-created.t'
);

notabs_ok($_) foreach @files;
done_testing;
