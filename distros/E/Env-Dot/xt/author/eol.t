use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/envdot',
    'lib/Env/Dot.pm',
    'lib/Env/Dot/Functions.pm',
    'lib/Env/Dot/ScriptFunctions.pm',
    't/env-dot-functions-private.t',
    't/env-dot-functions-public-unix.t',
    't/env-dot-functions-public-win32.t',
    't/env-dot-functions-public.t',
    't/env-dot-override-example-synopsis.sh',
    't/env-dot-override-example-synopsis.t',
    't/env-dot-scriptfunctions.t',
    't/envdot-script-first.env',
    't/envdot-script-second.env',
    't/envdot-script-third.env',
    't/envdot-script.t',
    't/file-read-order/ENVDOT_FILEPATHS.t',
    't/file-read-order/dummy.env-first',
    't/file-read-order/dummy.env-interpolation',
    't/file-read-order/dummy.env-second',
    't/file-read-order/dummy.env-static',
    't/file-read-order/dummy.env-third',
    't/lib/Env/Dot/Test/Utils.pm',
    't/lib/Test2/Deny/Platform/DOSOrDerivative.pm',
    't/lib/Test2/Require/Platform/DOSOrDerivative.pm',
    't/lib/Test2/Require/Platform/Unix.pm',
    't/other/read-from-this-deeper-file.t',
    't/other/read-from-this-file.t',
    't/recursive-read.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
