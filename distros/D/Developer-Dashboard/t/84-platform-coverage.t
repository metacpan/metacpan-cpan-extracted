#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use lib 'lib';

use Developer::Dashboard::Platform qw(
  native_shell_name
  normalize_shell_name
  shell_command_argv
  command_in_path
  resolve_runnable_file
  command_argv_for_path
  shell_quote_for
  passwd_user_name
  passwd_home_directory
);

# ---------------------------------------------------------------------------
# Hermetic runtime: temp HOME, chdir into it so any layer discovery resolves
# from an empty tree instead of the developer's real dashboard.
# ---------------------------------------------------------------------------
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "chdir $home: $!";

# Deterministic shell so native_shell_name() never dies or reads the operator's
# real environment while exercising the empty/undef selector paths.
local $ENV{SHELL} = '/bin/bash';

my $work = File::Spec->catdir( $home, 'work' );
mkdir $work or die "mkdir $work: $!";
my $bin = File::Spec->catdir( $home, 'bin' );
mkdir $bin or die "mkdir $bin: $!";

sub write_file {
    my ( $path, $body ) = @_;
    open my $fh, '>', $path or die "write $path: $!";
    print {$fh} $body;
    close $fh;
    return $path;
}

# Populate $bin so that exactly the named commands resolve through PATH.
sub only_commands {
    my %want = map { $_ => 1 } @_;
    for my $c (qw(python python3 node bash sh pwsh powershell)) {
        my $p = File::Spec->catfile( $bin, $c );
        if ( $want{$c} ) { write_file( $p, "#stub\n" ) }
        else             { unlink $p }
    }
    return;
}

my $win = 'MSWin32';

# ---------------------------------------------------------------------------
# native_shell_name / normalize_shell_name : line 44 + 65 + 66 + 67 + 71
# ---------------------------------------------------------------------------

# line 44 condition: requested defined+non-empty (row3), requested='' (row2),
# requested undef (row1 via no-arg call).
is( native_shell_name('bash'), 'bash', 'native_shell_name honours an explicit selector' );
is( native_shell_name(''),     'bash', 'native_shell_name empty-string falls back to the SHELL env' );
is( native_shell_name(),       'bash', 'native_shell_name() with no selector falls back' );

# line 65 branch true + condition rows: normalize called with undef and ''.
is( normalize_shell_name(),   'bash', 'normalize_shell_name() defaults to native shell' );
is( normalize_shell_name(''), 'bash', 'normalize_shell_name empty-string defaults to native shell' );

# line 65 branch false + line 71 operand chain (bash/zsh/sh/powershell/pwsh).
is( normalize_shell_name('bash'),       'bash',       'normalize keeps bash' );
is( normalize_shell_name('zsh'),        'zsh',        'normalize keeps zsh' );
is( normalize_shell_name('sh'),         'sh',         'normalize keeps sh' );
is( normalize_shell_name('powershell'), 'powershell', 'normalize keeps powershell' );
is( normalize_shell_name('pwsh'),       'pwsh',       'normalize keeps pwsh' );

# line 67 condition right side ($shell || ''): a false-but-defined selector
# collapses to '' and is then rejected as unsupported.
my $zero = eval { normalize_shell_name('0'); 1 };
ok( !$zero, "normalize_shell_name('0') dies as unsupported" );
like( $@, qr/Unsupported shell/, 'zero selector reports the unsupported-shell error' );

# line 71 all-operands-false path also reaches the unsupported die.
my $bad = eval { normalize_shell_name('ksh'); 1 };
ok( !$bad, 'an unknown shell name is rejected' );

# ---------------------------------------------------------------------------
# shell_command_argv : line 81 + 83 + 85 + 86
# ---------------------------------------------------------------------------

# line 81 branch true: missing command dies.
my $missing = eval { shell_command_argv(undef); 1 };
ok( !$missing, 'shell_command_argv(undef) dies' );
like( $@, qr/Missing shell command/, 'missing-command error surfaced' );

# line 83 condition: explicit shell arg (left true) vs default (left false,
# native right true).
is_deeply(
    [ shell_command_argv( 'echo hi', shell => 'bash' ) ],
    [ 'bash', '-c', 'echo hi' ],
    'explicit bash selector builds -c argv',
);
is_deeply(
    [ shell_command_argv('echo hi') ],
    [ 'bash', '-c', 'echo hi' ],
    'default selector resolves through native shell',
);

# line 85 operand rows: bash (left true), zsh (mid), sh (all-false-then-sh).
is_deeply( [ shell_command_argv( 'x', shell => 'zsh' ) ],           [ 'zsh', '-c', 'x' ], 'zsh argv' );
is_deeply( [ shell_command_argv( 'x', shell => 'sh' ) ],            [ 'sh',  '-c', 'x' ], 'sh argv' );
is_deeply( [ shell_command_argv( 'x', shell => 'bash', login => 1 ) ], [ 'bash', '-lc', 'x' ], 'login argv uses -lc' );

# line 86 operand rows: powershell (left true) vs pwsh (right true).
is_deeply(
    [ shell_command_argv( 'Get-Item', shell => 'powershell' ) ],
    [ 'powershell', '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-Command', 'Get-Item' ],
    'powershell argv',
);
is_deeply(
    [ shell_command_argv( 'Get-Item', shell => 'pwsh' ) ],
    [ 'pwsh', '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-Command', 'Get-Item' ],
    'pwsh argv',
);

# line 86 false side: a normalized-but-unsupported shell reaches neither the
# POSIX nor the PowerShell branch and falls through to the unsupported die.
{
    no warnings 'redefine';
    local *Developer::Dashboard::Platform::normalize_shell_name = sub { return 'fish' };
    my $ok = eval { shell_command_argv('printf ok'); 1 };
    ok( !$ok, 'shell_command_argv rejects an unsupported normalized shell (line 86 false)' );
    like( $@, qr/Unsupported shell 'fish'/, 'unsupported normalized shell surfaced' );
}

# ---------------------------------------------------------------------------
# command_in_path : line 97 + 104
# ---------------------------------------------------------------------------

# line 97 branch/condition true: undef and empty name.
ok( !defined command_in_path(undef), 'command_in_path(undef) returns undef' );
ok( !defined command_in_path(''),    'command_in_path empty-string returns undef' );

# line 104 branch + condition rows. File::Spec->path rewrites empty entries to
# '.', so drive the defensive guard by injecting an undef and an empty dir.
{
    no warnings 'redefine';
    local *File::Spec::Unix::path = sub { return ( undef, '', $bin ) };
    local $ENV{PATH} = $bin;
    only_commands('python');
    my $found = command_in_path('python');
    ok( defined $found, 'command_in_path still finds a real command past empty/undef PATH dirs' );
    ok( !defined command_in_path('definitely-absent-xyz'), 'an absent command returns undef' );
}

# ---------------------------------------------------------------------------
# resolve_runnable_file : line 129
# ---------------------------------------------------------------------------
ok( !defined resolve_runnable_file(undef), 'resolve_runnable_file(undef) returns undef' );
ok( !defined resolve_runnable_file(''),    'resolve_runnable_file empty-string returns undef' );

my $resolveme = File::Spec->catfile( $work, 'resolveme.sh' );
write_file( $resolveme, "echo x\n" );
chmod 0755, $resolveme;
is(
    resolve_runnable_file( File::Spec->catfile( $work, 'resolveme' ) ),
    $resolveme,
    'resolve_runnable_file appends a script suffix and returns the executable',
);

# ---------------------------------------------------------------------------
# command_argv_for_path : line 146 (ternary + || die) and line 161 (.bash)
# ---------------------------------------------------------------------------

my $bashfile = File::Spec->catfile( $work, 'plain.bash' );
write_file( $bashfile, "echo x\n" );    # no shebang
is(
    ( command_argv_for_path($bashfile) )[-1],
    $bashfile,
    'a .bash file resolves to a bash-backed argv (line 161 true)',
);

my $shfile = File::Spec->catfile( $work, 'plain.sh' );
write_file( $shfile, "echo x\n" );      # no shebang
is(
    ( command_argv_for_path($shfile) )[-1],
    $shfile,
    'a .sh file falls through .bash to the sh handler (line 161 false)',
);

# line 146 ternary false + || left-true: bare path resolved via suffix search.
is(
    ( command_argv_for_path( File::Spec->catfile( $work, 'resolveme' ) ) )[-1],
    $resolveme,
    'command_argv_for_path resolves an extension-less path (ternary false)',
);

# line 146 || right side: unresolvable path dies.
my $noresolve = eval { command_argv_for_path( File::Spec->catfile( $work, 'no-such-runnable' ) ); 1 };
ok( !$noresolve, 'command_argv_for_path dies when nothing resolves' );
like( $@, qr/Unable to find runnable file/, 'unresolvable path error surfaced' );

# ---------------------------------------------------------------------------
# _shebang_uses_perl : line 173 (open) + 176 (defined first)
# ---------------------------------------------------------------------------
my $empty = write_file( File::Spec->catfile( $work, 'empty.txt' ), '' );
my $noshebang = write_file( File::Spec->catfile( $work, 'plain.txt' ), "echo hi\n" );

{
    my $ok = eval { Developer::Dashboard::Platform::_shebang_uses_perl( File::Spec->catfile( $work, 'gone.txt' ) ); 1 };
    ok( !$ok, '_shebang_uses_perl dies on an unreadable path (line 173 true)' );
}
is( Developer::Dashboard::Platform::_shebang_uses_perl($empty),     0, 'empty file has no perl shebang (line 176 true)' );
is( Developer::Dashboard::Platform::_shebang_uses_perl($noshebang), 0, 'non-shebang file is not perl (line 176 false)' );

# ---------------------------------------------------------------------------
# shell_quote_for : line 187 + 189
# ---------------------------------------------------------------------------
is( shell_quote_for( 'bash', undef ), q{''},   'undef value quotes to empty string (line 187 true)' );
is( shell_quote_for( 'bash', q{a'b} ), q{'a'\''b'}, 'posix quoting escapes single quotes (line 189 false)' );
is( shell_quote_for( 'powershell', q{a'b} ), q{'a''b'}, 'powershell doubles single quotes (line 189 true, left)' );
is( shell_quote_for( 'pwsh', q{x} ),         q{'x'},    'pwsh uses powershell quoting (line 189 right)' );

# ---------------------------------------------------------------------------
# _path_candidates : line 210 (empty PATHEXT entry, Windows only)
# ---------------------------------------------------------------------------
{
    local $Developer::Dashboard::Platform::OS_NAME = $win;
    local $ENV{PATHEXT} = '.EXE;;.BAT';
    my @cands = Developer::Dashboard::Platform::_path_candidates('foo');
    ok( ( grep { $_ eq 'foo.exe' } @cands ), 'PATHEXT expansion runs on Windows for the .EXE entry' );
    ok( ( grep { $_ eq 'foo.bat' } @cands ), 'PATHEXT expansion runs on Windows for the .BAT entry' );
}

# ---------------------------------------------------------------------------
# _is_windows_runnable_candidate : lines 242, 243, 244, 245
# These functions do not gate on is_windows(), so they run directly on Linux.
# ---------------------------------------------------------------------------
my $pyfile = write_file( File::Spec->catfile( $work, 'prog.py' ), "print(1)\n" );
my $jsfile = write_file( File::Spec->catfile( $work, 'prog.js' ), "1\n" );
my $shcand = write_file( File::Spec->catfile( $work, 'cand.sh' ), "echo\n" );

my $iwrc = \&Developer::Dashboard::Platform::_is_windows_runnable_candidate;

{
    local $ENV{PATH} = $bin;

    # line 242: .py with python present / python3 present / neither.
    only_commands('python');
    is( $iwrc->($pyfile), 1, '.py runnable when python present' );
    only_commands('python3');
    is( $iwrc->($pyfile), 1, '.py runnable when only python3 present' );
    only_commands();
    is( $iwrc->($pyfile), 0, '.py not runnable when no python present' );

    # line 243: .js with node present / absent.
    only_commands('node');
    is( $iwrc->($jsfile), 1, '.js runnable when node present' );
    only_commands();
    is( $iwrc->($jsfile), 0, '.js not runnable when node absent' );

    # line 244: a Windows binary extension is always runnable.
    is( $iwrc->( File::Spec->catfile( $work, 'app.exe' ) ), 1, '.exe treated as runnable' );

    # line 245: .sh/.bash with bash present / sh present / neither.
    only_commands('bash');
    is( $iwrc->($shcand), 1, '.sh runnable when bash present' );
    only_commands('sh');
    is( $iwrc->($shcand), 1, '.sh runnable when only sh present' );
    only_commands();
    is( $iwrc->($shcand), 0, '.sh not runnable when neither bash nor sh present' );

    # line 242/244 false side: a plain data file that reaches the shebang check.
    is( $iwrc->($noshebang), 0, 'a non-shebang data file is not runnable' );
}

# ---------------------------------------------------------------------------
# _has_shebang : line 256 (open) + 259 (defined + regex)
# ---------------------------------------------------------------------------
my $shebang = write_file( File::Spec->catfile( $work, 'run.sh' ), "#!/bin/sh\necho\n" );
{
    my $ok = eval { Developer::Dashboard::Platform::_has_shebang( File::Spec->catfile( $work, 'absent.sh' ) ); 1 };
    ok( !$ok, '_has_shebang dies on an unreadable path (line 256 true)' );
}
is( Developer::Dashboard::Platform::_has_shebang($empty),     0, 'empty file has no shebang (line 259 row1)' );
is( Developer::Dashboard::Platform::_has_shebang($noshebang), 0, 'plain text has no shebang (line 259 row2)' );
is( Developer::Dashboard::Platform::_has_shebang($shebang),   1, 'shebang detected (line 259 row3)' );

# ---------------------------------------------------------------------------
# interpreter resolvers : lines 267, 275, 283, 305
# ---------------------------------------------------------------------------
{
    local $ENV{PATH} = $bin;

    only_commands('pwsh');
    is( Developer::Dashboard::Platform::_powershell_binary(), File::Spec->catfile( $bin, 'pwsh' ), 'pwsh preferred when present' );
    only_commands('powershell');
    is( Developer::Dashboard::Platform::_powershell_binary(), File::Spec->catfile( $bin, 'powershell' ), 'powershell used when pwsh absent' );
    only_commands();
    is( Developer::Dashboard::Platform::_powershell_binary(), 'powershell', 'powershell name is the final fallback' );

    only_commands('python');
    is( Developer::Dashboard::Platform::_python_binary(), File::Spec->catfile( $bin, 'python' ), 'python preferred when present' );
    only_commands('python3');
    is( Developer::Dashboard::Platform::_python_binary(), File::Spec->catfile( $bin, 'python3' ), 'python3 used when python absent' );
    only_commands();
    is( Developer::Dashboard::Platform::_python_binary(), 'python', 'python name is the final fallback' );

    only_commands('node');
    is( Developer::Dashboard::Platform::_node_binary(), File::Spec->catfile( $bin, 'node' ), 'node used when present' );
    only_commands();
    is( Developer::Dashboard::Platform::_node_binary(), 'node', 'node name is the final fallback' );

    only_commands('bash');
    is( Developer::Dashboard::Platform::_posix_shell_binary('bash'), File::Spec->catfile( $bin, 'bash' ), 'preferred posix shell used when present' );
    only_commands('sh');
    is( Developer::Dashboard::Platform::_posix_shell_binary('bash'), File::Spec->catfile( $bin, 'sh' ), 'sh used when preferred absent' );
    only_commands();
    is( Developer::Dashboard::Platform::_posix_shell_binary('bash'), 'bash', 'preferred name is the final fallback' );
}

# ---------------------------------------------------------------------------
# _module_lib_root : line 314 (%INC present vs fallback to __FILE__)
# ---------------------------------------------------------------------------
my $root_from_inc = Developer::Dashboard::Platform::_module_lib_root();
ok( length $root_from_inc, '_module_lib_root resolves via %INC' );
{
    local $INC{'Developer/Dashboard/Platform.pm'} = undef;
    my $root_from_file = Developer::Dashboard::Platform::_module_lib_root();
    ok( length $root_from_file, '_module_lib_root falls back to __FILE__ when %INC is empty' );
}

# ---------------------------------------------------------------------------
# _exec_go_source : line 325 + 326
# ---------------------------------------------------------------------------
{
    my $ok = eval { Developer::Dashboard::Platform::_exec_go_source(undef); 1 };
    ok( !$ok, '_exec_go_source(undef) dies (line 325 row1)' );
    $ok = eval { Developer::Dashboard::Platform::_exec_go_source(''); 1 };
    ok( !$ok, '_exec_go_source empty-string dies (line 325 row2)' );
}
{
    local $Developer::Dashboard::Platform::EXEC_LAUNCHER = sub { 1 };
    my $ret = eval { Developer::Dashboard::Platform::_exec_go_source('prog.go'); 1 };
    ok( $ret, '_exec_go_source returns when the launcher succeeds (line 326 false)' );
}
{
    local $Developer::Dashboard::Platform::EXEC_LAUNCHER = sub { 0 };
    my $ok = eval { Developer::Dashboard::Platform::_exec_go_source('prog.go'); 1 };
    ok( !$ok, '_exec_go_source dies when the launcher fails (line 326 true)' );
    like( $@, qr/Unable to exec go run/, 'go-run failure surfaced' );
}

# ---------------------------------------------------------------------------
# _java_main_class : line 361 + 363
# ---------------------------------------------------------------------------
{
    my $ok = eval { Developer::Dashboard::Platform::_java_main_class(undef); 1 };
    ok( !$ok, '_java_main_class(undef) dies (line 361 row1)' );
    $ok = eval { Developer::Dashboard::Platform::_java_main_class(''); 1 };
    ok( !$ok, '_java_main_class empty-string dies (line 361 row2)' );
    $ok = eval { Developer::Dashboard::Platform::_java_main_class( File::Spec->catfile( $work, 'Missing.java' ) ); 1 };
    ok( !$ok, '_java_main_class dies on an unreadable source (line 363 true)' );
}

my $hello = write_file(
    File::Spec->catfile( $work, 'Hello.java' ),
    "package demo;\npublic class Hello { public static void main(String[] a) {} }\n",
);
is(
    Developer::Dashboard::Platform::_java_main_class($hello),
    'demo.Hello',
    '_java_main_class returns the fully qualified class (line 361/363 false)',
);

# ---------------------------------------------------------------------------
# _exec_java_source : line 336 + 340 + 345 + 351
# ---------------------------------------------------------------------------
{
    my $ok = eval { Developer::Dashboard::Platform::_exec_java_source(undef); 1 };
    ok( !$ok, '_exec_java_source(undef) dies (line 336 row1)' );
    $ok = eval { Developer::Dashboard::Platform::_exec_java_source(''); 1 };
    ok( !$ok, '_exec_java_source empty-string dies (line 336 row2)' );
}

# line 340 branch true: a source whose class name cannot be resolved. A file
# literally named ".java" strips to an empty class, so _java_main_class returns
# '' and the extracted simple class is undef.
{
    my $dotjava = File::Spec->catfile( $work, '.java' );
    write_file( $dotjava, "// no declarations\n" );
    my $ok = eval { Developer::Dashboard::Platform::_exec_java_source($dotjava); 1 };
    ok( !$ok, '_exec_java_source dies when the main class is unresolvable (line 340 true)' );
    like( $@, qr/Unable to resolve Java main class/, 'unresolvable-class error surfaced' );
}

# line 345 false + line 351 both sides: fake javac and the launcher so the whole
# happy path runs without a real toolchain.
{
    local $Developer::Dashboard::Platform::SYSTEM_LAUNCHER = sub { $? = 0; 1 };
    local $Developer::Dashboard::Platform::EXEC_LAUNCHER   = sub { 1 };
    my $ret = eval { Developer::Dashboard::Platform::_exec_java_source($hello); 1 };
    ok( $ret, '_exec_java_source stages, compiles and returns on the happy path (line 345/351 false)' );
}
{
    local $Developer::Dashboard::Platform::SYSTEM_LAUNCHER = sub { $? = 0; 1 };
    local $Developer::Dashboard::Platform::EXEC_LAUNCHER   = sub { 0 };
    my $ok = eval { Developer::Dashboard::Platform::_exec_java_source($hello); 1 };
    ok( !$ok, '_exec_java_source dies when the java launcher fails (line 351 true)' );
    like( $@, qr/Unable to exec java/, 'java exec failure surfaced' );
}

# ---------------------------------------------------------------------------
# _passwd_entry / passwd_user_name / passwd_home_directory : the Windows
# short-circuit, the absent-record outcome, and the resolved record.
# ---------------------------------------------------------------------------
{
    # A uid that owns no passwd record on the test host, so the "no record"
    # outcome is exercised with the real lookup instead of a stub.
    my $absent_uid = 4294967294;

    my @real = getpwuid($<);
    is( passwd_user_name($<),      $real[0], 'passwd_user_name resolves the account name' );
    is( passwd_home_directory($<), $real[7], 'passwd_home_directory resolves the home directory' );

    is( passwd_user_name($absent_uid),      undef, 'passwd_user_name reports undef for an absent record' );
    is( passwd_home_directory($absent_uid), undef, 'passwd_home_directory reports undef for an absent record' );

    # Windows perl leaves the passwd functions unimplemented, so the lookup is
    # never attempted there.
    {
        local $Developer::Dashboard::Platform::OS_NAME = $win;
        is_deeply( [ Developer::Dashboard::Platform::_passwd_entry($<) ], [],
            '_passwd_entry skips the lookup entirely on Windows' );
        is( passwd_user_name($<),      undef, 'passwd_user_name reports undef on Windows' );
        is( passwd_home_directory($<), undef, 'passwd_home_directory reports undef on Windows' );
    }
}

done_testing;

__END__

=pod

=head1 NAME

t/84-platform-coverage.t - branch and condition coverage closure for the platform helpers

=head1 PURPOSE

This test drives every remaining branch and condition edge in the platform and
shell helper module so the coverage gate can prove that command resolution,
shell-selector normalization, script-extension handling, and the source-runner
launchers behave the same way on every decision path, not merely on the common
one exercised by higher-level tests.

=head1 WHY IT EXISTS

The platform helpers concentrate all of the operating-system-specific launch
logic in one place, and most of that logic is only reached indirectly by the CLI
and web layers. That left individual guard clauses - empty PATH entries, missing
interpreters, unresolvable script paths, unreadable sources, and failed
launchers - uncovered even though the statements around them ran. This file
exists to exercise each of those guards directly and deterministically, so a
future refactor of the launch rules cannot silently drop a defensive path.

=head1 WHEN TO USE

Use this file when changing executable resolution, script-extension mapping,
shell-selector normalization, the Windows PATHEXT expansion, the PowerShell
versus pwsh choice, or the Go and Java source-runner helpers.

=head1 HOW TO USE

Run C<prove -lv t/84-platform-coverage.t> while iterating on the module, and keep
it green under C<prove -lr t>. To confirm the branch and condition metrics it is
meant to close, run it under Devel::Cover and inspect the Platform report.

=head1 WHAT USES IT

The repository test suite and the coverage gate use this file to keep the
platform helpers at full branch and condition coverage. Developers changing
launch behavior use it as the fast regression check for the decision paths.

=head1 EXAMPLES

Example 1:

  prove -lv t/84-platform-coverage.t

Run the platform coverage-closure check by itself while iterating.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Run it inside the full suite under the coverage gate before release.

=cut
