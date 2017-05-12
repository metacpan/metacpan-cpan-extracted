
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
    'lib/Math/Int64.pm',
    'lib/Math/Int64/die_on_overflow.pm',
    'lib/Math/Int64/native_if_available.pm',
    'lib/Math/UInt64.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/MSC.t',
    't/Math-Int64-Native.t',
    't/Math-Int64.t',
    't/Math-UInt64-Native.t',
    't/Math-UInt64.t',
    't/as_int64.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/die_on_overflow.t',
    't/pow.t',
    't/release-cpan-changes.t',
    't/release-pod-coverage.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/storable.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
