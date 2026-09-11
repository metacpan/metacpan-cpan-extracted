#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);

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
# DD-765: a bare name must never resolve against the CWD. The process is
# already chdir'd into $home (see the hermetic-runtime block at the top of
# this file), which is exactly the shape of the real bug - a file sitting in
# the directory dashboard happens to be run from, sharing a name with a real
# command. PATH is restricted to $bin (which does not contain 'make'), so a
# fix-correct resolver must return undef here, never the cwd shadow file.
# ---------------------------------------------------------------------------
{
    my $shadow = File::Spec->catfile( $home, 'make' );
    write_file( $shadow, "#!/bin/sh\necho shadow\n" );
    chmod 0755, $shadow;
    local $ENV{PATH} = $bin;
    my $found = command_in_path('make');
    ok( !defined $found,
        'command_in_path never resolves a same-named file sitting in the cwd, only PATH (DD-765)' );
    unlink $shadow;
}

# A caller passing an actual PATH-separator-bearing path (not a bare name)
# is asking a different question, and that path is still resolved directly -
# this is the branch that stays reachable after DD-765's fix.
{
    my $subdir = File::Spec->catdir( $home, 'toolsub' );
    mkdir $subdir or die "mkdir $subdir: $!";
    my $explicit = File::Spec->catfile( $subdir, 'explicit-tool' );
    write_file( $explicit, "#!/bin/sh\necho explicit\n" );
    chmod 0755, $explicit;
    my $rel = File::Spec->abs2rel($explicit);
    local $ENV{PATH} = $bin;
    is( command_in_path($rel), $rel,
        'command_in_path still resolves an explicit path containing a directory separator (DD-765)' );
    unlink $explicit;

    # And the false side of that same -f check: a separator-bearing path that
    # does not exist there falls through to a genuine PATH search rather than
    # short-circuiting on the strength of merely looking like a path.
    local $ENV{PATH} = $bin;
    ok( !defined command_in_path( File::Spec->catfile( $subdir, 'no-such-tool' ) ),
        'command_in_path with a separator-bearing but nonexistent path falls through, never fabricates a hit (DD-765)' );
    rmdir $subdir;
}

# Every path command_in_path DOES return must be absolute - a relative result
# denotes a different file once the caller's cwd changes (DD-765 AC-2).
{
    only_commands('python');
    local $ENV{PATH} = $bin;
    my $found = command_in_path('python');
    ok( $found && File::Spec->file_name_is_absolute($found),
        'command_in_path returns an absolute path, never relative (DD-765 AC-2)' );
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

# DD-825: go run must be launched with -C <the source file's own directory>,
# not a bare `go run <path>` - a bare invocation lets go.mod discovery walk up
# from the CALLER's cwd rather than the skill's own directory, so a skill's
# go.mod is silently missed unless the caller happens to already be inside it.
{
    my @seen_argv;
    local $Developer::Dashboard::Platform::EXEC_LAUNCHER = sub { @seen_argv = @_; return 1 };
    my $go_path = File::Spec->catfile( $work, 'skill', 'cli', 'foo.go' );
    eval { Developer::Dashboard::Platform::_exec_go_source($go_path); 1 };
    is_deeply(
        \@seen_argv,
        [ 'go', 'run', '-C', File::Spec->catdir( $work, 'skill', 'cli' ), $go_path ],
        '_exec_go_source passes -C <source dir> so go.mod discovery starts at the skill layer, not the caller cwd'
    );
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

# DD-597: the javac launch mutates the caller's global $? as a side effect
# (the sub reads it into its own $exit_code); without a guard at the sub's
# entry that stays set in the caller's process after the sub returns via the
# die path (the only path that can return control to a caller at all - a
# successful exec replaces the process image).
{
    local $Developer::Dashboard::Platform::SYSTEM_LAUNCHER = sub { $? = 7 << 8; 1 };    ## no critic (Variables::RequireLocalizedPunctuationVars)
    $? = 12 << 8;                                                                       ## no critic (Variables::RequireLocalizedPunctuationVars)
    eval { Developer::Dashboard::Platform::_exec_java_source($hello); 1 };
    is( $? >> 8, 12, '_exec_java_source does not leak javac\'s exit status into the caller global $? on the die path' );
}

# ---------------------------------------------------------------------------
# DD-823: _find_layer_pom + _exec_java_source_via_mvn - per-skill-layer
# config/pom.xml dependency resolution, falling back to plain javac when no
# layer in the file's ancestry has one.
# ---------------------------------------------------------------------------
{
    ok( !defined Developer::Dashboard::Platform::_find_layer_pom( File::Spec->catfile( $work, 'nolayer', 'cli', 'Foo.java' ) ),
        '_find_layer_pom returns undef when no ancestor layer has a config/pom.xml' );
}
{
    my $skill = File::Spec->catdir( $work, 'skill' );
    my $cli   = File::Spec->catdir( $skill, 'cli' );
    my $config = File::Spec->catdir( $skill, 'config' );
    mkdir $skill; mkdir $cli; mkdir $config;
    my $pom = write_file( File::Spec->catfile( $config, 'pom.xml' ), "<project/>\n" );
    my $foo = write_file( File::Spec->catfile( $cli, 'Foo.java' ), "package demo;\npublic class Foo { public static void main(String[] a) {} }\n" );

    is( Developer::Dashboard::Platform::_find_layer_pom($foo), $pom, '_find_layer_pom finds the layer pom.xml walking up from the source file' );

    # AC-2: a file with no config/pom.xml anywhere in its ancestry still
    # takes the plain-javac path, unchanged.
    is( Developer::Dashboard::Platform::_find_layer_pom($hello), undef, '_find_layer_pom returns undef for a file whose ancestry has no pom.xml' );

    # AC-1: when a layer pom.xml exists, _exec_java_source dispatches to mvn
    # instead of javac, and passes the resolved classpath (layer's own
    # target/classes plus mvn's dependency:build-classpath output) to java.
    my @mvn_calls;
    my $cp_written;
    local $Developer::Dashboard::Platform::SYSTEM_LAUNCHER = sub {
        push @mvn_calls, [@_];
        if ( $_[0] eq 'mvn' && grep { $_ eq 'dependency:build-classpath' } @_ ) {
            my ($outfile) = grep { /^-Dmdep\.outputFile=/ } @_;
            $outfile =~ s/^-Dmdep\.outputFile=//;
            open my $fh, '>', $outfile or die $!;
            print {$fh} "/fake/dep1.jar:/fake/dep2.jar";
            close $fh;
            $cp_written = 1;
        }
        $? = 0;    ## no critic (Variables::RequireLocalizedPunctuationVars)
        return 1;
    };
    my @java_exec;
    local $Developer::Dashboard::Platform::EXEC_LAUNCHER = sub { @java_exec = @_; return 1 };

    my $ret = eval { Developer::Dashboard::Platform::_exec_java_source( $foo, 'alpha' ); 1 };
    ok( $ret, '_exec_java_source with a layer pom.xml dispatches to mvn instead of javac' );
    is( scalar(@mvn_calls), 2, 'mvn was invoked exactly twice - compile then dependency:build-classpath' );
    is_deeply( $mvn_calls[0], [ 'mvn', '-f', $pom, '-q', 'compile' ], 'first mvn call compiles the layer module' );
    ok( $cp_written, 'the dependency:build-classpath mvn call resolved a classpath file' );
    is( $java_exec[0], 'java', 'java is invoked to run the resolved main class' );
    is( $java_exec[1], '-cp', 'the -cp flag is passed' );
    like( $java_exec[2], qr{\Q/target/classes\E:/fake/dep1\.jar:/fake/dep2\.jar\z}, 'classpath includes the layer target/classes plus mvn-resolved dependencies' );
    is( $java_exec[3], 'demo.Foo', 'the resolved fully-qualified class is execed' );
    is( $java_exec[4], 'alpha', 'passthrough argv reaches java' );

    # AC-3: a second, independent skill layer with its own pom.xml resolves
    # against its own layer root, with no interference between the two.
    my $skill2 = File::Spec->catdir( $work, 'skill2' );
    my $cli2   = File::Spec->catdir( $skill2, 'cli' );
    my $config2 = File::Spec->catdir( $skill2, 'config' );
    mkdir $skill2; mkdir $cli2; mkdir $config2;
    my $pom2 = write_file( File::Spec->catfile( $config2, 'pom.xml' ), "<project/>\n" );
    my $bar = write_file( File::Spec->catfile( $cli2, 'Bar.java' ), "package other;\npublic class Bar { public static void main(String[] a) {} }\n" );
    is( Developer::Dashboard::Platform::_find_layer_pom($bar), $pom2, 'a second skill layer resolves its OWN pom.xml, independent of the first' );

    # mvn compile failure surfaces.
    local $Developer::Dashboard::Platform::SYSTEM_LAUNCHER = sub { $? = 3 << 8; return 1 };    ## no critic (Variables::RequireLocalizedPunctuationVars)
    my $failed = eval { Developer::Dashboard::Platform::_exec_java_source($foo); 1 };
    ok( !$failed, '_exec_java_source dies when mvn compile fails' );
    like( $@, qr/mvn compile failed/, 'mvn compile failure surfaced' );
}

# DD-823: the remaining branches of _exec_java_source_via_mvn - the
# dependency:build-classpath mvn call failing, the classpath file being
# unreadable, an empty resolved classpath (ternary's other side), and the
# final java exec failing.
{
    my $skill = File::Spec->catdir( $work, 'skill3' );
    my $cli   = File::Spec->catdir( $skill, 'cli' );
    my $config = File::Spec->catdir( $skill, 'config' );
    mkdir $skill; mkdir $cli; mkdir $config;
    my $pom = write_file( File::Spec->catfile( $config, 'pom.xml' ), "<project/>\n" );
    my $baz = write_file( File::Spec->catfile( $cli, 'Baz.java' ), "package demo3;\npublic class Baz { public static void main(String[] a) {} }\n" );

    # dependency:build-classpath mvn call fails.
    {
        local $Developer::Dashboard::Platform::SYSTEM_LAUNCHER = sub {
            $? = ( $_[0] eq 'mvn' && grep { $_ eq 'dependency:build-classpath' } @_ ) ? ( 5 << 8 ) : 0;    ## no critic (Variables::RequireLocalizedPunctuationVars)
            return 1;
        };
        my $ok = eval { Developer::Dashboard::Platform::_exec_java_source($baz); 1 };
        ok( !$ok, '_exec_java_source dies when mvn dependency:build-classpath fails' );
        like( $@, qr/mvn dependency:build-classpath failed/, 'dependency:build-classpath failure surfaced' );
    }

    # the resolved classpath file is unreadable (mvn "succeeds" but never
    # writes the file the caller was told to expect).
    {
        local $Developer::Dashboard::Platform::SYSTEM_LAUNCHER = sub { $? = 0; return 1 };    ## no critic (Variables::RequireLocalizedPunctuationVars)
        my $ok = eval { Developer::Dashboard::Platform::_exec_java_source($baz); 1 };
        ok( !$ok, '_exec_java_source dies when the resolved classpath file cannot be read' );
        like( $@, qr/Unable to read resolved classpath/, 'unreadable classpath file surfaced' );
    }

    # an EMPTY resolved classpath (mvn writes nothing to declare) exercises
    # the ternary's other side: classpath is just the layer's target/classes,
    # with no ":dependency" suffix.
    {
        local $Developer::Dashboard::Platform::SYSTEM_LAUNCHER = sub {
            if ( $_[0] eq 'mvn' && grep { $_ eq 'dependency:build-classpath' } @_ ) {
                my ($outfile) = grep { /^-Dmdep\.outputFile=/ } @_;
                $outfile =~ s/^-Dmdep\.outputFile=//;
                open my $fh, '>', $outfile or die $!;
                close $fh;
            }
            $? = 0;    ## no critic (Variables::RequireLocalizedPunctuationVars)
            return 1;
        };
        my @java_exec;
        local $Developer::Dashboard::Platform::EXEC_LAUNCHER = sub { @java_exec = @_; return 1 };
        my $ok = eval { Developer::Dashboard::Platform::_exec_java_source($baz); 1 };
        ok( $ok, '_exec_java_source succeeds with an empty resolved classpath' );
        like( $java_exec[2], qr{\Q/target/classes\E\z}, 'an empty dependency classpath leaves just the layer target/classes, no trailing colon-suffix' );
    }

    # the final java exec fails.
    {
        local $Developer::Dashboard::Platform::SYSTEM_LAUNCHER = sub {
            if ( $_[0] eq 'mvn' && grep { $_ eq 'dependency:build-classpath' } @_ ) {
                my ($outfile) = grep { /^-Dmdep\.outputFile=/ } @_;
                $outfile =~ s/^-Dmdep\.outputFile=//;
                open my $fh, '>', $outfile or die $!;
                print {$fh} '/fake/dep.jar';
                close $fh;
            }
            $? = 0;    ## no critic (Variables::RequireLocalizedPunctuationVars)
            return 1;
        };
        local $Developer::Dashboard::Platform::EXEC_LAUNCHER = sub { return 0 };
        my $ok = eval { Developer::Dashboard::Platform::_exec_java_source($baz); 1 };
        ok( !$ok, '_exec_java_source dies when the java launcher fails (mvn path)' );
        like( $@, qr/Unable to exec java/, 'java exec failure surfaced (mvn path)' );
    }
}

# ---------------------------------------------------------------------------
# DD-824: _find_layer_venv_python + command_argv_for_path's .py dispatch -
# per-skill-layer local/venv python resolution, falling back to the global
# python when no layer in the file's ancestry has one.
# ---------------------------------------------------------------------------
{
    ok( !defined Developer::Dashboard::Platform::_find_layer_venv_python( File::Spec->catfile( $work, 'nolayer', 'cli', 'foo.py' ) ),
        '_find_layer_venv_python returns undef when no ancestor layer has a local/venv' );
}
{
    my $skill = File::Spec->catdir( $work, 'pyskill' );
    my $cli   = File::Spec->catdir( $skill, 'cli' );
    my $venv_bin = File::Spec->catdir( $skill, 'local', 'venv', 'bin' );
    mkdir $skill; mkdir $cli;
    make_path($venv_bin) if !-d $venv_bin;
    my $venv_python = write_file( File::Spec->catfile( $venv_bin, 'python' ), "#!/bin/sh\n" );
    chmod 0755, $venv_python;
    my $foo = write_file( File::Spec->catfile( $cli, 'foo.py' ), "print('hi')\n" );

    is( Developer::Dashboard::Platform::_find_layer_venv_python($foo), $venv_python,
        '_find_layer_venv_python finds the layer local/venv/bin/python walking up from the source file' );

    # AC-2: a .py file with no local/venv anywhere in its ancestry still
    # resolves through the global python, unchanged.
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Platform::command_in_path = sub { return '/usr/local/bin/python' };
        my $hello = write_file( File::Spec->catfile( $work, 'hello.py' ), "print('hi')\n" );
        is_deeply(
            [ command_argv_for_path($hello) ],
            [ '/usr/local/bin/python', $hello ],
            'command_argv_for_path falls back to the global python when no layer venv exists (AC-2)'
        );
    }

    # AC-1: a .py file whose layer DOES have a local/venv resolves through
    # that venv's own python interpreter, not the global one.
    is_deeply(
        [ command_argv_for_path($foo) ],
        [ $venv_python, $foo ],
        "command_argv_for_path resolves through the layer's own venv python when one exists (AC-1)"
    );

    # AC-3: a second, independent skill layer with its own venv resolves
    # against its own venv, with no interference between the two.
    my $skill2 = File::Spec->catdir( $work, 'pyskill2' );
    my $cli2   = File::Spec->catdir( $skill2, 'cli' );
    my $venv_bin2 = File::Spec->catdir( $skill2, 'local', 'venv', 'bin' );
    mkdir $skill2; mkdir $cli2;
    make_path($venv_bin2) if !-d $venv_bin2;
    my $venv_python2 = write_file( File::Spec->catfile( $venv_bin2, 'python' ), "#!/bin/sh\n" );
    chmod 0755, $venv_python2;
    my $bar = write_file( File::Spec->catfile( $cli2, 'bar.py' ), "print('hi')\n" );
    is( Developer::Dashboard::Platform::_find_layer_venv_python($bar), $venv_python2,
        "a second skill layer resolves its OWN local/venv, independent of the first (AC-3)" );
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
