use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.14

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Config/Slicer.pm',
    'lib/Dist/Zilla/PluginBundle/ConfigSlicer.pm',
    'lib/Dist/Zilla/Role/PluginBundle/Config/Slicer.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/bundle-filter.t',
    't/bundle-role.t',
    't/lib/Dist/Zilla/Config/Slicer/Test/Bundle.pm',
    't/lib/Dist/Zilla/Config/Slicer/Test/Bundle/Easy.pm',
    't/lib/Dist/Zilla/PluginBundle/Near_Empty.pm',
    't/slicer.t'
);

notabs_ok($_) foreach @files;
done_testing;
