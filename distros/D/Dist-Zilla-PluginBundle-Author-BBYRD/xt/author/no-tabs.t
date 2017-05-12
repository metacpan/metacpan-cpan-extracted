use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/MintingProfile/Author/BBYRD.pm',
    'lib/Dist/Zilla/PluginBundle/Author/BBYRD.pm',
    'lib/Pod/Weaver/PluginBundle/Author/BBYRD.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t'
);

notabs_ok($_) foreach @files;
done_testing;
