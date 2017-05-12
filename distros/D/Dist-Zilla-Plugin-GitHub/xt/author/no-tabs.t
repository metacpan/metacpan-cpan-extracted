use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/App/Command/gh.pm',
    'lib/Dist/Zilla/Plugin/GitHub.pm',
    'lib/Dist/Zilla/Plugin/GitHub/Create.pm',
    'lib/Dist/Zilla/Plugin/GitHub/Meta.pm',
    'lib/Dist/Zilla/Plugin/GitHub/Update.pm',
    'lib/Dist/Zilla/PluginBundle/GitHub.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-update.t',
    'xt/author/00-compile.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t'
);

notabs_ok($_) foreach @files;
done_testing;
