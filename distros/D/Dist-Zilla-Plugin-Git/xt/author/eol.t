use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/Git.pm',
    'lib/Dist/Zilla/Plugin/Git/Check.pm',
    'lib/Dist/Zilla/Plugin/Git/Commit.pm',
    'lib/Dist/Zilla/Plugin/Git/CommitBuild.pm',
    'lib/Dist/Zilla/Plugin/Git/GatherDir.pm',
    'lib/Dist/Zilla/Plugin/Git/Init.pm',
    'lib/Dist/Zilla/Plugin/Git/NextVersion.pm',
    'lib/Dist/Zilla/Plugin/Git/Push.pm',
    'lib/Dist/Zilla/Plugin/Git/Tag.pm',
    'lib/Dist/Zilla/PluginBundle/Git.pm',
    'lib/Dist/Zilla/Role/Git/DirtyFiles.pm',
    'lib/Dist/Zilla/Role/Git/Repo.pm',
    'lib/Dist/Zilla/Role/Git/StringFormatter.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/000-report-git-version.t',
    't/Util.pm',
    't/check.t',
    't/commit-build-custom.t',
    't/commit-build-src-as-parent.t',
    't/commit-build.t',
    't/commit-dirtydir.t',
    't/commit-message.t',
    't/commit-utf8.t',
    't/commit-ws.t',
    't/commit.t',
    't/gatherdir-multi.t',
    't/gatherdir.t',
    't/lib/Dist/Zilla/Plugin/MyTestArchiver.pm',
    't/push-gitconfig.t',
    't/push-multi.t',
    't/push.t',
    't/repo-dir.t',
    't/tag-signed.t',
    't/tag.t',
    't/version-by-branch.t',
    't/version-default.t',
    't/version-extraction.t',
    't/version-regexp.t',
    't/zzz-check-breaks.t',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/mojibake.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
