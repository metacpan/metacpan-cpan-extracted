use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Role/PluginBundle/PluginRemover.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/bundle.t',
    't/lib/Dist/Zilla/PluginBundle/CustomRemover.pm',
    't/lib/Dist/Zilla/PluginBundle/EasyRemover.pm',
    't/lib/Dist/Zilla/PluginBundle/TestRemover.pm',
    't/remove.t'
);

notabs_ok($_) foreach @files;
done_testing;
