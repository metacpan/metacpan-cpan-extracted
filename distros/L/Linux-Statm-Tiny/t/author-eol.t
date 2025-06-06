
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Linux/Statm/Tiny.pm',
    'lib/Linux/Statm/Tiny.pm.mite.pm',
    'lib/Linux/Statm/Tiny/Mite.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10-basic.t',
    't/20-fork.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-no-tabs.t',
    't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',
    't/release-check-manifest.t',
    't/release-fixme.t',
    't/release-trailing-space.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
