use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Devel/Leak/Object.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/001_basic.t',
    't/002_inherit.t',
    't/003_rebless.t',
    't/004_auto.t',
    't/005_STDERR_at_end.t',
    't/006_track_source_of_leaks.t',
    't/tracksource.pl',
    't/tracksource.pm',
    't/tracksource2.pl',
    'xt/author/changes_has_content.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/pod-no404s.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
