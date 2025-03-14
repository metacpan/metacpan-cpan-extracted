use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Plugin/StaticInstall.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-auto.t',
    't/03-dry_run.t',
    't/04-on-fatal.t',
    't/05-mbt-auto.t',
    't/06-off-notfatal.t',
    't/07-two-sources-good.t',
    't/08-two-sources-bad.t',
    't/09-two-sources-ugly.t',
    't/10-dry_run-not-auto.t',
    't/lib/SimpleFlagSetter.pm',
    't/zzz-check-breaks.t',
    'xt/author/00-compile.t',
    'xt/author/changes_has_content.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-no404s.t',
    'xt/author/pod-spell.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t'
);

notabs_ok($_) foreach @files;
done_testing;
