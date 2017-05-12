
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
    'lib/HTML/FormHandlerX/JQueryRemoteValidator.pm',
    't/00-load.t',
    't/01-tests.t',
    't/author-critic.t',
    't/author-eol.t',
    't/lib/TestForm.pm',
    't/manifest.t',
    't/pod-coverage.t',
    't/pod.t',
    't/release-check-changes.t',
    't/release-cpan-changes.t',
    't/release-pod-coverage.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
