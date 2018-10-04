use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Git/MoreHooks.pm',
    'lib/Git/MoreHooks/CheckCommitAuthorFromMailmap.pm',
    'lib/Git/MoreHooks/CheckCommitBase.pm',
    'lib/Git/MoreHooks/CheckIndent.pm',
    'lib/Git/MoreHooks/TriggerJenkins.pm',
    't/CheckCommitAuthorFromMailmap-hooks.t',
    't/CheckCommitAuthorFromMailmap-load.t',
    't/CheckIndent-functions.t',
    't/TriggerJenkins-functions.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
