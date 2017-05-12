
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
    'lib/Mason/Plugin/WithEncoding.pm',
    'lib/Mason/Plugin/WithEncoding/Test/Class.pm',
    'lib/Mason/Plugin/WithEncoding/t/NoUTF8.pm',
    'lib/Mason/Plugin/WithEncoding/t/UTF8.pm',
    't/00-load.t~',
    't/NoUTF8.t',
    't/NoUTF8.t~',
    't/UTF8.t',
    't/author-critic.t',
    't/author-eol.t',
    't/manifest.t',
    't/pod.t',
    't/release-check-changes.t',
    't/release-cpan-changes.t',
    't/release-pod-coverage.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
