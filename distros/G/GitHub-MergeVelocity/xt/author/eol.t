use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/GitHub/MergeVelocity.pm',
    'lib/GitHub/MergeVelocity/Repository.pm',
    'lib/GitHub/MergeVelocity/Repository/PullRequest.pm',
    'lib/GitHub/MergeVelocity/Repository/Statistics.pm',
    'lib/GitHub/MergeVelocity/Types.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/GitHub/MergeVelocity.t',
    't/GitHub/MergeVelocity/Repository.t',
    't/GitHub/MergeVelocity/Repository/PullRequest.t',
    't/GitHub/MergeVelocity/Repository/Statistics.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
