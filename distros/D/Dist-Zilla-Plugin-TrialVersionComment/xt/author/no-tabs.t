use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Plugin/TrialVersionComment.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-not-trial.t',
    't/03-already-has-comment.t',
    't/04-multiple-packages.t',
    't/05-comments.t',
    't/06-my-version.t',
    't/07-fully-qualified.t',
    't/10-pkgversion.t',
    't/11-ourpkgversion.t',
    't/12-rewriteversion.t',
    't/13-overridepkgversion.t',
    't/14-surgicalpkgversion.t',
    't/15-pgkversionifmodulewithpod.t',
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
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t',
    'xt/release/portability.t'
);

notabs_ok($_) foreach @files;
done_testing;
