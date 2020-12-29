use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/Author/CSSON/GithubActions.pm',
    'lib/Dist/Zilla/Plugin/Author/CSSON/GithubActions/Workflow/TestWithMakefile.pm',
    'lib/Dist/Zilla/Role/Author/CSSON/GithubActions.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/corpus/lib/Dist/Zilla/Plugin/TestForGithubActions.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
