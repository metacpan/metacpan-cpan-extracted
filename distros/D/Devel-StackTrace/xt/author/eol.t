use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Devel/StackTrace.pm',
    'lib/Devel/StackTrace/Frame.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-bad-utf8.t',
    't/03-message.t',
    't/04-indent.t',
    't/05-back-compat.t',
    't/06-dollar-at.t',
    't/07-no-args.t',
    't/08-filter-early.t',
    't/09-skip-frames.t',
    't/10-set-frames.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
