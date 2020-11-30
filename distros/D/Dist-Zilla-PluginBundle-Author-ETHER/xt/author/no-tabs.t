use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/MintingProfile/Author/ETHER.pm',
    'lib/Dist/Zilla/PluginBundle/Author/ETHER.pm',
    'lib/Pod/Weaver/PluginBundle/Author/ETHER.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-pluginbundle-basic.t',
    't/02-minter-github.t',
    't/03-pluginbundle-server.t',
    't/04-pluginbundle-installer.t',
    't/05-pluginbundle-core.t',
    't/06-airplane.t',
    't/07-minter-dzil-plugin.t',
    't/08-minter-dzil-plugin-shorter.t',
    't/09-copy-files-from-release.t',
    't/10-extra_args.t',
    't/11-minter-default.t',
    't/12-podweaver-pluginbundle.t',
    't/13-pluginbundle-podweaver-config.t',
    't/14-pluginbundle-weaver-ini.t',
    't/15-weaver-expand-config.t',
    't/16-podweaver-licence.t',
    't/17-podweaver-support.t',
    't/18-versionmanagement.t',
    't/19-add_bundle.t',
    't/21-remove-plugin.t',
    't/22-plugin_prereqs.t',
    't/23-cpanfile.t',
    't/24-bugtracker.t',
    't/lib/Helper.pm',
    't/lib/NoNetworkHits.pm',
    't/lib/NoPrereqChecks.pm',
    't/zzz-check-breaks.t',
    'xt/author/00-compile.t',
    'xt/author/changes_has_content.t',
    'xt/author/clean-namespaces.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-spell.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t'
);

notabs_ok($_) foreach @files;
done_testing;
