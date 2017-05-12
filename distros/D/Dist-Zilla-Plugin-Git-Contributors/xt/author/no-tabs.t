use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Plugin/Git/Contributors.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-include-authors.t',
    't/03-no-contributors.t',
    't/04-podweaver-warning.t',
    't/05-no-repository.t',
    't/06-include-releaser.t',
    't/07-author-is-releaser.t',
    't/08-order-by.t',
    't/09-unicode.t',
    't/10-no-git-user-configured.t',
    't/11-paths.t',
    't/12-mailmap-files.t',
    't/13-no-commits.t',
    't/14-extract-author.t',
    't/15-remove.t',
    't/16-duplicates.t',
    't/17-json-pp-injection.t',
    't/18-all-files.t',
    't/lib/GitSetup.pm',
    't/zzz-check-breaks.t',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-no404s.t',
    'xt/author/pod-spell.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t'
);

notabs_ok($_) foreach @files;
done_testing;
