
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/File/chmod.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-critic.t',
    't/author-eol.t',
    't/executable.t',
    't/load_chmod.t',
    't/read.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-meta-json.t',
    't/release-minimum-version.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t',
    't/release-portability.t',
    't/release-test-version.t',
    't/release-unused-vars.t',
    't/remove-write-from-other.t',
    't/sticky-bit.t',
    't/write.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
