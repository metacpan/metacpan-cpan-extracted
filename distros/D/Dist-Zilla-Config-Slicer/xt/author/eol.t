use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
