use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/File/ShareDir/Install.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10_makefile.t',
    't/11_dotfile.t',
    't/12_delete.t',
    't/module/.dir/something',
    't/module/.something',
    't/module/again',
    't/module/bonk',
    't/module/deeper/bonk',
    't/share/#hello',
    't/share/.dir/something',
    't/share/.something',
    't/share/hello world',
    't/share/honk',
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
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
