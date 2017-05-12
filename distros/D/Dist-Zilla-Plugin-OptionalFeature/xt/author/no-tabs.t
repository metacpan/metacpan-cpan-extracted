use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Plugin/OptionalFeature.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-no-configure.t',
    't/03-name-syntax.t',
    't/04-default.t',
    't/05-require-develop.t',
    't/06-prompt.t',
    't/07-multiple-features.t',
    't/08-prompt-no-check-prereqs.t',
    't/lib/SpecCompliant.pm',
    't/zzz-check-breaks.t',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-spell.t',
    'xt/author/pod-syntax.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t',
    'xt/release/pod-no404s.t',
    'xt/release/portability.t'
);

notabs_ok($_) foreach @files;
done_testing;
