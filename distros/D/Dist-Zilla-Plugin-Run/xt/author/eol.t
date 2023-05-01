use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/Run.pm',
    'lib/Dist/Zilla/Plugin/Run/AfterBuild.pm',
    'lib/Dist/Zilla/Plugin/Run/AfterMint.pm',
    'lib/Dist/Zilla/Plugin/Run/AfterRelease.pm',
    'lib/Dist/Zilla/Plugin/Run/BeforeArchive.pm',
    'lib/Dist/Zilla/Plugin/Run/BeforeBuild.pm',
    'lib/Dist/Zilla/Plugin/Run/BeforeRelease.pm',
    'lib/Dist/Zilla/Plugin/Run/Clean.pm',
    'lib/Dist/Zilla/Plugin/Run/Release.pm',
    'lib/Dist/Zilla/Plugin/Run/Role/Runner.pm',
    'lib/Dist/Zilla/Plugin/Run/Test.pm',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10_build_phase.t',
    't/20_formatter.t',
    't/30_all_phases.t',
    't/40_test_phase.t',
    't/50_mint.t',
    't/60_redacted_configs.t',
    't/70-eval.t',
    't/80-fatal-errors.t',
    't/90-clean.t',
    't/91-release-status.t',
    't/92-quiet.t',
    't/93-eval-scopes.t',
    't/lib/TestHelper.pm',
    't/zzz-check-breaks.t',
    'xt/author/00-compile.t',
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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
