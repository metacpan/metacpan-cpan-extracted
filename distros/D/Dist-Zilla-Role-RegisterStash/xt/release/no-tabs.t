use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Role/RegisterStash.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/000-report-versions-tiny.t',
    't/basic.t',
    't/lib/Dist/Zilla/Plugin/TestAddStash.pm',
    't/lib/Dist/Zilla/Plugin/TestAddStash2.pm',
    't/lib/Dist/Zilla/Stash/TestStash.pm',
    't/retrieve_or_register.t'
);

notabs_ok($_) foreach @files;
done_testing;
