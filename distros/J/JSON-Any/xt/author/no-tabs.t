use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/JSON/Any.pm',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-JSON.t',
    't/02-JSON-XS.t',
    't/03-JSON-DWIW.t',
    't/04-ENV.t',
    't/05-JSON-Syck.t',
    't/06-JSON-PP.t',
    't/07-CPanel-JSON-XS.t',
    't/10_unicode.t',
    't/11-string-escape.t',
    't/12-boolean.t',
    't/13-no-backends.t',
    't/14-deprecated.t',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/distmeta.t',
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
    'xt/release/cpan-changes.t'
);

notabs_ok($_) foreach @files;
done_testing;
