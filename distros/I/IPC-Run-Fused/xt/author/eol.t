use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/IPC/Run/Fused.pm',
    'lib/IPC/Run/Fused/POSIX.pm',
    'lib/IPC/Run/Fused/Win32.pm',
    't/00-compile/lib_IPC_Run_Fused_POSIX_pm.t',
    't/00-compile/lib_IPC_Run_Fused_Win32_pm.t',
    't/00-compile/lib_IPC_Run_Fused_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-captures-all.t',
    't/02-captures-nodelay.t',
    't/03-captures-nodelay-fork.t',
    't/04-win32-stringy-params.t',
    't/tbin/01.pl'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
