use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Git/Helpers.pm',
    'lib/Git/Helpers/CPAN.pm',
    'script/cpan-repo',
    'script/delete-git-branches',
    'script/gh-open',
    'script/travis-open',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-diag.t',
    't/cpan-repo.t',
    't/helpers.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
