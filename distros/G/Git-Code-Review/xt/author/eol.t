use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/git-code-review',
    'lib/Git/Code/Review.pm',
    'lib/Git/Code/Review/Command/comment.pm',
    'lib/Git/Code/Review/Command/config.pm',
    'lib/Git/Code/Review/Command/diff.pm',
    'lib/Git/Code/Review/Command/fixed.pm',
    'lib/Git/Code/Review/Command/info.pm',
    'lib/Git/Code/Review/Command/init.pm',
    'lib/Git/Code/Review/Command/list.pm',
    'lib/Git/Code/Review/Command/mailhandler.pm',
    'lib/Git/Code/Review/Command/move.pm',
    'lib/Git/Code/Review/Command/overdue.pm',
    'lib/Git/Code/Review/Command/pick.pm',
    'lib/Git/Code/Review/Command/profile.pm',
    'lib/Git/Code/Review/Command/report.pm',
    'lib/Git/Code/Review/Command/select.pm',
    'lib/Git/Code/Review/Command/show.pm',
    'lib/Git/Code/Review/Command/tutorial.pm',
    'lib/Git/Code/Review/Helpers.pm',
    'lib/Git/Code/Review/Notify.pm',
    'lib/Git/Code/Review/Notify/Email.pm',
    'lib/Git/Code/Review/Notify/JIRA.pm',
    'lib/Git/Code/Review/Notify/STDOUT.pm',
    'lib/Git/Code/Review/Tutorial.pm',
    'lib/Git/Code/Review/Utilities.pm',
    'lib/Git/Code/Review/Utilities/Date.pm',
    't/00-compile.t',
    't/05-date.t',
    't/holidays.txt'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
