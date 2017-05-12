
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::EOLTests 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/ChangesFromYaml.pm',
    'lib/Dist/Zilla/Plugin/ChangesFromYaml/Convert.pm',
    't/00-compile.t',
    't/000-report-versions-tiny.t',
    't/01basic.t',
    't/02dateformat.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/author-test-version.t',
    't/release-distmeta.t',
    't/release-eol.t',
    't/release-no-tabs.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
