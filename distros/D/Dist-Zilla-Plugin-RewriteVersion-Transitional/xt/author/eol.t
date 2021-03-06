use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/BumpVersionAfterRelease/Transitional.pm',
    'lib/Dist/Zilla/Plugin/RewriteVersion/Transitional.pm',
    'lib/Dist/Zilla/Role/InsertVersion.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-rewriteversion.t',
    't/03-ourpkgversion.t',
    't/04-private-package.t',
    't/05-two-packages.t',
    't/06-missing-fallback-no-version.t',
    't/07-missing-fallback-have-version.t',
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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
