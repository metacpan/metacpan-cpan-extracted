use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

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

notabs_ok($_) foreach @files;
done_testing;
