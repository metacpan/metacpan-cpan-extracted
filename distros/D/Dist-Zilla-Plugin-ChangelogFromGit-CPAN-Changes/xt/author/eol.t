use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/ChangelogFromGit/CPAN/Changes.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/changes.t',
    't/changes/first_release',
    't/changes/v1_defaults',
    't/changes/v1_email',
    't/changes/v1_group_author',
    't/changes/v1_group_author_email',
    't/changes/v1_no_author',
    't/first_release.t',
    't/lib/Test/DZP/Changes.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
