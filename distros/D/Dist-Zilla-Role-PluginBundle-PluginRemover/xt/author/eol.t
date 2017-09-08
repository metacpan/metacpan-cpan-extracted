use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
