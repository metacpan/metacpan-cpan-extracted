use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/ContributorsFromGit.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/000-report-versions-tiny.t',
    't/author-map.t',
    't/basic.t',
    't/validate-public-interface.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
