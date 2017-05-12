use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/Chrome/ExtraPrompt.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-no-distini.t',
    't/03-repeat-prompt.t',
    't/04-error.t',
    't/05-kill.t',
    't/lib/TestPrompter.pm',
    't/zzz-check-breaks.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
