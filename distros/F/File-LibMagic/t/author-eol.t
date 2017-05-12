
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/File/LibMagic.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-00-compile.t',
    't/author-eol.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/author-test-version.t',
    't/constructor-params.t',
    't/lib/Test/AnyOf.pm',
    't/lib/Test/Exports.pm',
    't/old-apis/all-exports.t',
    't/old-apis/complete-interface-errors.t',
    't/old-apis/complete-interface.t',
    't/old-apis/easy-interface.t',
    't/oo-api.t',
    't/release-cpan-changes.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/release-tidyall.t',
    't/samples/foo.c',
    't/samples/foo.foo',
    't/samples/foo.txt',
    't/samples/magic',
    't/samples/magic.mime',
    't/version.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
