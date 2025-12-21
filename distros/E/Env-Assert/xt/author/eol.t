use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/envassert',
    'lib/Env/Assert.pm',
    'lib/Env/Assert/Functions.pm',
    't/env-assert-private.t',
    't/env-assert-public-assert.t',
    't/env-assert-public-report_errors.t',
    't/env-assert.t',
    't/env-assert/another-envdesc',
    't/envassert-script-stdin.t',
    't/envassert-script.t',
    't/lib/Test2/Deny/Platform/CI/GitHubCI.pm',
    't/lib/Test2/Deny/Platform/OS/DOSOrDerivative.pm',
    't/lib/Test2/Require/Platform/CI/GitHubCI.pm',
    't/lib/Test2/Require/Platform/OS/DOSOrDerivative.pm',
    't/lib/Test2/Require/Platform/OS/Unix.pm',
    't/one/.envdesc',
    't/three/.envdesc',
    't/three/another-envdesc',
    't/three/bin/using-another.pl',
    't/three/bin/using-script.pl',
    't/three/envassert-script.t',
    't/two/.envdesc'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
