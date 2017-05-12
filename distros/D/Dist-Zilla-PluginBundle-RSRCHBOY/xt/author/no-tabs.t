use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/PluginBundle/RSRCHBOY.pm',
    'lib/Pod/Weaver/PluginBundle/RSRCHBOY.pm',
    'lib/Pod/Weaver/Section/RSRCHBOY/Authors.pm',
    'lib/Pod/Weaver/Section/RSRCHBOY/GeneratedAttributes.pm',
    'lib/Pod/Weaver/Section/RSRCHBOY/LazyAttributes.pm',
    'lib/Pod/Weaver/Section/RSRCHBOY/RequiredAttributes.pm',
    'lib/Pod/Weaver/Section/RSRCHBOY/RoleParameters.pm',
    'lib/Pod/Weaver/SectionBase/CollectWithIntro.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t'
);

notabs_ok($_) foreach @files;
done_testing;
