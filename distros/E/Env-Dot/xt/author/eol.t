use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Env/Dot.pm',
    'lib/Env/Dot/Functions.pm',
    'lib/Env/Dot/ScriptFunctions.pm',
    'script/envdot',
    't/env-dot-functions-private.t',
    't/env-dot-private.t',
    't/env-dot-public/dotenv',
    't/env-dot-public/env-dot-public.t',
    't/env-dot-scriptfunctions.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
