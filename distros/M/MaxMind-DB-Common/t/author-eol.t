
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
    'lib/MaxMind/DB/Common.pm',
    'lib/MaxMind/DB/Metadata.pm',
    'lib/MaxMind/DB/Role/Debugs.pm',
    'lib/MaxMind/DB/Types.pm',
    'lib/Test/MaxMind/DB/Common/Data.pm',
    'lib/Test/MaxMind/DB/Common/Util.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/MaxMind/DB/Common.t',
    't/MaxMind/DB/Metadata.t',
    't/author-00-compile.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/author-test-version.t',
    't/compile.t',
    't/release-cpan-changes.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/release-tidyall.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
