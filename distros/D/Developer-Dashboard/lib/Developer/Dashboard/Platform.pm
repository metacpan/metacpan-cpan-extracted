package Developer::Dashboard::Platform;

use strict;
use warnings;

our $VERSION = '4.31';

use Exporter 'import';
use File::Basename qw(basename dirname);
use File::Copy qw(copy);
use File::Spec;
use File::Temp qw(tempdir);

our @EXPORT_OK = qw(
  is_windows
  native_shell_name
  normalize_shell_name
  shell_command_argv
  command_in_path
  is_runnable_file
  resolve_runnable_file
  command_argv_for_path
  shell_quote_for
  passwd_user_name
  passwd_home_directory
);

our $OS_NAME = $^O;
our $EXEC_LAUNCHER = sub { exec @_ };
our $SYSTEM_LAUNCHER = sub { system @_ };

# is_windows()
# Detects whether the active Perl runtime is running on Windows.
# Input: none.
# Output: boolean true for Strawberry/Windows-style runtimes, false otherwise.
sub is_windows {
    return $OS_NAME eq 'MSWin32' ? 1 : 0;
}

# _passwd_entry($uid)
# Reads one passwd database record without ever letting the lookup itself abort
# the caller. Windows perl leaves the passwd functions unimplemented and dies
# when one is called, so the lookup is skipped there outright, and the eval
# keeps any other runtime without a usable passwd database from propagating a
# fatal error into a fallback chain.
# Input: numeric user id.
# Output: list of passwd record fields, or the empty list when no record is resolvable.
sub _passwd_entry {
    my ($uid) = @_;
    return () if is_windows();
    my @entry = eval { getpwuid($uid) };
    return @entry;
}

# passwd_user_name($uid)
# Resolves the account name recorded for one user id.
# Input: numeric user id.
# Output: account name string, or undef when the passwd database cannot answer.
sub passwd_user_name {
    my ($uid) = @_;
    my @entry = _passwd_entry($uid);
    return @entry ? $entry[0] : undef;
}

# passwd_home_directory($uid)
# Resolves the home directory recorded for one user id.
# Input: numeric user id.
# Output: home directory path string, or undef when the passwd database cannot answer.
sub passwd_home_directory {
    my ($uid) = @_;
    my @entry = _passwd_entry($uid);
    return @entry ? $entry[7] : undef;
}

# native_shell_name($requested)
# Chooses the most suitable interactive shell name for the current platform.
# Input: optional requested shell selector or executable path.
# Output: normalized shell name string.
sub native_shell_name {
    my ($requested) = @_;
    return normalize_shell_name($requested) if defined $requested && $requested ne '';

    if (is_windows()) {
        return command_in_path('pwsh') ? 'pwsh' : 'powershell';
    }

    my $shell = $ENV{SHELL} || '';
    $shell =~ s{.*[\\/]}{} if $shell ne '';
    return normalize_shell_name($shell) if $shell ne '';

    return 'bash' if command_in_path('bash');
    return 'zsh'  if command_in_path('zsh');
    return 'sh';
}

# normalize_shell_name($shell)
# Normalizes user-provided shell selectors and common aliases into supported names.
# Input: optional shell selector string or executable path.
# Output: normalized shell name string or dies when unsupported.
sub normalize_shell_name {
    my ($shell) = @_;
    $shell = native_shell_name() if !defined $shell || $shell eq '';
    $shell =~ s{.*[\\/]}{} if defined $shell;    # uncoverable branch false
    $shell = lc( $shell || '' );

    return 'powershell' if $shell eq 'ps' || $shell eq 'powershell.exe';
    return 'pwsh'       if $shell eq 'pwsh.exe';
    return $shell if $shell eq 'bash' || $shell eq 'zsh' || $shell eq 'sh' || $shell eq 'powershell' || $shell eq 'pwsh';
    die "Unsupported shell '$shell'\n";
}

# shell_command_argv($command, %args)
# Builds the argv list used to execute one shell command string on the current platform.
# Input: command string plus optional shell selector override and login boolean.
# Output: command argv list suitable for system/open3.
sub shell_command_argv {
    my ( $command, %args ) = @_;
    die "Missing shell command\n" if !defined $command;

    my $shell = normalize_shell_name( $args{shell} || native_shell_name() );    # uncoverable condition false
    my $login = $args{login} ? 1 : 0;
    return ( $shell, $login ? '-lc' : '-c', $command ) if $shell eq 'bash' || $shell eq 'zsh' || $shell eq 'sh';
    return ( $shell, '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-Command', $command )
      if $shell eq 'powershell' || $shell eq 'pwsh';
    die "Unsupported shell '$shell'\n";
}

# command_in_path($name)
# Resolves a command name from PATH using PATHEXT semantics on Windows when needed.
# Input: bare command name.
# Output: absolute executable path string or undef when not found.
sub command_in_path {
    my ($name) = @_;
    return if !defined $name || $name eq '';

    # DD-765: a BARE name (no directory separator) is a request to search
    # PATH - the caller's cwd is not on PATH, and never was. Testing the
    # bare name as a relative filesystem path here resolved it against the
    # process's cwd, so a same-named file sitting in whatever directory
    # dashboard happened to be run from was preferred over the real PATH
    # executable and returned as a RELATIVE string - a dot-in-PATH hazard
    # reached without dot ever being on PATH, and unconditionally wrong the
    # moment any caller's cwd changes between the check and the use. Every
    # current caller passes a bare name, so this loop never had a legitimate
    # reason to exist; a caller with an actual path does not need this
    # resolver at all.
    if ( $name =~ m{[\\/]} ) {
        for my $candidate ( _path_candidates($name) ) {
            return $candidate if -f $candidate;
        }
    }

    for my $dir ( File::Spec->path ) {
        next if !defined $dir || $dir eq '';
        for my $candidate ( _path_candidates( File::Spec->catfile( $dir, $name ) ) ) {
            return $candidate if -f $candidate;
        }
    }

    return;
}

# is_runnable_file($path)
# Checks whether one file path should be treated as runnable on this platform.
# Input: file path string.
# Output: boolean true when the file can be executed by dashboard helpers.
sub is_runnable_file {
    my ($path) = @_;
    my $resolved = resolve_runnable_file($path);
    return $resolved ? 1 : 0;
}

# resolve_runnable_file($path)
# Resolves one logical runnable file path, including Windows script extensions.
# Input: requested file path string.
# Output: concrete runnable file path string or undef when unavailable.
sub resolve_runnable_file {
    my ($path) = @_;
    return if !defined $path || $path eq '';

    for my $candidate ( _runnable_path_candidates($path) ) {
        next if !-f $candidate;
        return $candidate if !is_windows() && -x $candidate;
        return $candidate if is_windows() && _is_windows_runnable_candidate($candidate);
    }

    return;
}

# command_argv_for_path($path)
# Resolves the argv list required to execute one script or runnable file path.
# Input: file path string.
# Output: command argv list suitable for exec/system/open3.
sub command_argv_for_path {
    my ($path) = @_;
    my $resolved = ( -f $path ? $path : resolve_runnable_file($path) ) || die "Unable to find runnable file for $path";
    my $lower = lc $resolved;

    return ( $^X, '-I', _module_lib_root(), $resolved ) if $lower =~ /\.pl\z/;
    if ( $lower =~ /\.py\z/ ) {
        my $venv_python = _find_layer_venv_python($resolved);
        return ( $venv_python, $resolved ) if defined $venv_python;
        return ( _python_binary(), $resolved );
    }
    return ( _node_binary(), $resolved ) if $lower =~ /\.js\z/;
    return ( $^X, '-I', _module_lib_root(), '-MDeveloper::Dashboard::Platform', '-e', 'Developer::Dashboard::Platform::_exec_go_source(@ARGV)', $resolved )
      if $lower =~ /\.go\z/;
    return ( $^X, '-I', _module_lib_root(), '-MDeveloper::Dashboard::Platform', '-e', 'Developer::Dashboard::Platform::_exec_java_source(@ARGV)', $resolved )
      if $lower =~ /\.java\z/;
    return ( $^X, '-I', _module_lib_root(), $resolved ) if !is_windows() && _shebang_uses_perl($resolved);
    return ($resolved) if !is_windows() && _has_shebang($resolved);
    return ( _powershell_binary(), '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $resolved )
      if $lower =~ /\.ps1\z/;
    return ( _cmd_binary(), '/d', '/c', $resolved ) if $lower =~ /\.(?:cmd|bat)\z/;
    return ( _posix_shell_binary('bash'), $resolved ) if $lower =~ /\.bash\z/;
    return ( _posix_shell_binary('sh'),   $resolved ) if $lower =~ /\.sh\z/;
    return ($resolved) if !is_windows();
    return ($^X, $resolved);
}

# _shebang_uses_perl($path)
# Detects whether one shebang-backed script should run through the current Perl interpreter.
# Input: file path string.
# Output: boolean true when the shebang names perl.
sub _shebang_uses_perl {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my $first = <$fh>;
    close $fh;
    return 0 if !defined $first;
    return $first =~ /^#!.*\bperl(?:\s|\z)/ ? 1 : 0;
}

# shell_quote_for($shell, $value)
# Quotes one scalar for interpolation into generated shell bootstrap scripts.
# Input: normalized shell name plus scalar string value.
# Output: safely quoted shell token string.
sub shell_quote_for {
    my ( $shell, $value ) = @_;
    $shell = normalize_shell_name($shell);
    $value = '' if !defined $value;

    if ( $shell eq 'powershell' || $shell eq 'pwsh' ) {
        $value =~ s/'/''/g;
        return "'$value'";
    }

    $value =~ s/'/'\\''/g;
    return "'$value'";
}

# _path_candidates($path)
# Builds filename candidates for a command/path, including PATHEXT variants on Windows.
# Input: command or path string.
# Output: ordered list of candidate path strings.
sub _path_candidates {
    my ($path) = @_;
    my @candidates = ($path);
    return @candidates if !is_windows();
    return @candidates if $path =~ /\.[^\\\/.]+\z/;

    my @extensions = split /;/, ( $ENV{PATHEXT} || '.COM;.EXE;.BAT;.CMD;.PS1' );
    for my $ext (@extensions) {
        next if $ext eq '';
        push @candidates, $path . lc($ext);
        push @candidates, $path . uc($ext);
    }
    return @candidates;
}

# _runnable_path_candidates($path)
# Expands one logical command path into runnable file candidates, including
# dashboard-supported source-script extensions when the caller omits them.
# Input: command or file path string.
# Output: ordered list of candidate path strings.
sub _runnable_path_candidates {
    my ($path) = @_;
    my @candidates = _path_candidates($path);
    return @candidates if $path =~ /\.[^\\\/.]+\z/;

    for my $suffix (qw(.pl .py .js .go .java .ps1 .cmd .bat .sh .bash)) {
        push @candidates, _path_candidates( $path . $suffix );
    }

    my %seen;
    return grep { !$seen{$_}++ } @candidates;
}

# _is_windows_runnable_candidate($path)
# Determines whether one existing Windows file should be treated as runnable.
# Input: concrete existing file path.
# Output: boolean true for executable/script candidates, false for data files.
sub _is_windows_runnable_candidate {
    my ($path) = @_;
    return 1 if $path =~ /\.(?:pl|ps1)\z/i;
    return 1 if $path =~ /\.py\z/i && ( command_in_path('python') || command_in_path('python3') );
    return 1 if $path =~ /\.js\z/i && command_in_path('node');
    return 1 if $path =~ /\.(?:com|exe|bat|cmd)\z/i;
    return 1 if $path =~ /\.(?:sh|bash)\z/i && ( command_in_path('bash') || command_in_path('sh') );
    return 1 if _has_shebang($path);
    return 0;
}

# _has_shebang($path)
# Detects whether one text file starts with a Unix shebang.
# Input: file path string.
# Output: boolean true when the file starts with #!.
sub _has_shebang {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my $first = <$fh>;
    close $fh;
    return defined $first && $first =~ /^#!/ ? 1 : 0;
}

# _powershell_binary()
# Resolves the preferred PowerShell executable name for the current platform.
# Input: none.
# Output: executable path or command name string.
sub _powershell_binary {
    return command_in_path('pwsh') || command_in_path('powershell') || 'powershell';
}

# _python_binary()
# Resolves the preferred Python executable name for Python-backed hooks and commands.
# Input: none.
# Output: executable path or command name string.
sub _python_binary {
    return command_in_path('python') || command_in_path('python3') || 'python';
}

# _find_layer_venv_python($path)
# Walks up from a .py file's own directory looking for a DD-OOP-LAYERS skill
# layer's own local/venv (DD-824) - reuses the existing per-layer walk
# pattern (same as DD-823's _find_layer_pom) rather than inventing a new
# top-level convention.
# Input: Python source file path.
# Output: absolute venv python interpreter path string, or undef when no
# layer in the file's ancestry has one.
sub _find_layer_venv_python {
    my ($path) = @_;
    my $dir = dirname($path);
    while (1) {
        my $python = is_windows()
          ? File::Spec->catfile( $dir, 'local', 'venv', 'Scripts', 'python.exe' )
          : File::Spec->catfile( $dir, 'local', 'venv', 'bin',     'python' );
        return $python if -f $python;
        my $parent = dirname($dir);
        last if $parent eq $dir;    # reached filesystem root
        $dir = $parent;
    }
    return undef;
}

# _node_binary()
# Resolves the preferred Node.js executable name for JavaScript-backed hooks and commands.
# Input: none.
# Output: executable path or command name string.
sub _node_binary {
    return command_in_path('node') || 'node';
}

# _cmd_binary()
# Resolves the Windows command processor used for .cmd and .bat scripts.
# Input: none.
# Output: executable path or command name string, normalized back to cmd.exe
# when PATH or ComSpec resolves through a generic cmd shim instead of the
# canonical Windows command processor name.
sub _cmd_binary {
    my $candidate = $ENV{ComSpec} || command_in_path('cmd') || 'cmd.exe';
    my $base = lc( basename($candidate) );
    return 'cmd.exe' if $base eq 'cmd.exe' || $base eq 'cmd';
    return $candidate;
}

# _posix_shell_binary($preferred)
# Resolves a POSIX shell interpreter when one is explicitly needed for script execution.
# Input: preferred shell command name such as bash or sh.
# Output: executable path or command name string.
sub _posix_shell_binary {
    my ($preferred) = @_;
    return command_in_path($preferred) || command_in_path('sh') || $preferred;    # uncoverable condition false
}

# _module_lib_root()
# Resolves the lib root that contains this loaded Platform module so child perl
# wrappers can force the same module version they were built from.
# Input: none.
# Output: absolute lib root path string.
sub _module_lib_root {
    my $path = $INC{'Developer/Dashboard/Platform.pm'} || __FILE__;
    return dirname( dirname( dirname($path) ) );
}

# _exec_go_source($path, @args)
# Re-execs one executable Go source file through go run so hook and command
# launch code can treat it like any other runnable script. Passes -C <the
# source file's own directory> (Go 1.20+) so go.mod discovery starts at the
# file's own skill layer instead of walking up from the caller's cwd - a
# bare `go run <path>` silently misses a skill's own go.mod unless the
# caller happens to already be inside that directory tree (DD-825).
# Input: Go source file path plus passthrough argv.
# Output: does not return on success; dies when exec fails.
sub _exec_go_source {
    my ( $path, @args ) = @_;
    die "Missing Go source path\n" if !defined $path || $path eq '';
    $EXEC_LAUNCHER->( 'go', 'run', '-C', dirname($path), $path, @args ) or die "Unable to exec go run for $path: $!";
}

# _find_layer_pom($path)
# Walks up from a source file's own directory looking for a DD-OOP-LAYERS
# skill layer's config/pom.xml - reuses the existing per-layer walk pattern
# rather than inventing a new top-level convention (DD-823).
# Input: source file path.
# Output: absolute pom.xml path string, or undef when no layer has one.
sub _find_layer_pom {
    my ($path) = @_;
    my $dir = dirname($path);
    while (1) {
        my $pom = File::Spec->catfile( $dir, 'config', 'pom.xml' );
        return $pom if -f $pom;
        my $parent = dirname($dir);
        last if $parent eq $dir;    # reached filesystem root
        $dir = $parent;
    }
    return undef;
}

# _exec_java_source($path, @args)
# Runs one executable Java source file. When its DD-OOP-LAYERS skill layer
# carries a config/pom.xml, builds and resolves dependencies through mvn
# (DD-823) so a layer's declared Maven dependencies are available; otherwise
# falls back to compiling standalone with javac into an isolated temp
# directory exactly as before, unchanged.
# Input: Java source file path plus passthrough argv.
# Output: does not return on success; dies when compilation or exec fails.
sub _exec_java_source {
    my ( $path, @args ) = @_;

    # DD-597: the javac/mvn launches below mutate the caller's global $? as a
    # side effect; without this guard that stays set in the caller's process
    # after this sub returns (the die path only - a successful exec below
    # replaces the process image and never returns).
    local $?;
    die "Missing Java source path\n" if !defined $path || $path eq '';

    my $class = _java_main_class($path);
    my ($simple_class) = $class =~ /([^\.]+)\z/;
    die "Unable to resolve Java main class for $path\n" if !defined $simple_class;

    my $pom = _find_layer_pom($path);
    return _exec_java_source_via_mvn( $pom, $class, @args ) if defined $pom;

    my $build_root = tempdir( CLEANUP => 1 );
    my $source_root = tempdir( CLEANUP => 1 );
    my $staged_source = File::Spec->catfile( $source_root, $simple_class . '.java' );
    copy( $path, $staged_source ) or die "Unable to stage Java source $path as $staged_source: $!";    # uncoverable branch true

    $SYSTEM_LAUNCHER->( 'javac', '-d', $build_root, $staged_source );
    my $exit_code = $? >> 8;
    die "javac failed for $path with exit code $exit_code\n" if $exit_code != 0;

    $EXEC_LAUNCHER->( 'java', '-cp', $build_root, $class, @args ) or die "Unable to exec java for $path: $!";
}

# _exec_java_source_via_mvn($pom, $class, @args)
# Builds one skill layer through its own config/pom.xml (treating the layer
# as one Maven module) and execs the resolved main class with mvn's declared
# dependencies on the classpath (DD-823).
# Input: pom.xml path, fully qualified main class name, passthrough argv.
# Output: does not return on success; dies when build or exec fails.
sub _exec_java_source_via_mvn {
    my ( $pom, $class, @args ) = @_;

    # DD-597 convention: the mvn launches below mutate the caller's global $?
    # as a side effect; without this guard that stays set in the caller's
    # process after this sub returns (the die path only - a successful exec
    # replaces the process image and never returns).
    local $?;
    my $layer_root = dirname( dirname($pom) );

    $SYSTEM_LAUNCHER->( 'mvn', '-f', $pom, '-q', 'compile' );
    my $compile_exit = $? >> 8;
    die "mvn compile failed for $pom with exit code $compile_exit\n" if $compile_exit != 0;

    my $cp_file = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'classpath.txt' );
    $SYSTEM_LAUNCHER->( 'mvn', '-f', $pom, '-q', 'dependency:build-classpath', "-Dmdep.outputFile=$cp_file" );
    my $cp_exit = $? >> 8;
    die "mvn dependency:build-classpath failed for $pom with exit code $cp_exit\n" if $cp_exit != 0;

    open my $fh, '<', $cp_file or die "Unable to read resolved classpath $cp_file: $!";

    my $dependency_classpath = do { local $/; <$fh> } // '';    # uncoverable condition right
    close $fh;
    $dependency_classpath =~ s/\s+\z//;

    my $classes_dir = File::Spec->catdir( $layer_root, 'target', 'classes' );
    my $classpath = $dependency_classpath eq '' ? $classes_dir : "$classes_dir:$dependency_classpath";

    $EXEC_LAUNCHER->( 'java', '-cp', $classpath, $class, @args ) or die "Unable to exec java for $pom: $!";
}

# _java_main_class($path)
# Resolves the fully qualified Java main class name from one source file,
# honoring an optional package declaration.
# Input: Java source file path.
# Output: class name string suitable for java -cp execution.
sub _java_main_class {
    my ($path) = @_;
    die "Missing Java source path\n" if !defined $path || $path eq '';

    open my $fh, '<', $path or die "Unable to read $path: $!";
    my $package = '';
    my $class = '';
    while ( my $line = <$fh> ) {
        if ( $line =~ /^\s*package\s+([A-Za-z_][A-Za-z0-9_\.]*)\s*;/ ) {
            $package = $1;
            next;
        }
        if ( $line =~ /^\s*(?:public\s+)?(?:final\s+|abstract\s+)?(?:class|interface|enum|record)\s+([A-Za-z_][A-Za-z0-9_]*)\b/ ) {
            $class = $1;
            last;
        }
    }
    close $fh;

    if ( $class eq '' ) {
        $class = basename($path);
        $class =~ s/\.java\z//i;
    }

    return $package eq '' ? $class : $package . '.' . $class;
}

1;

__END__

=head1 NAME

Developer::Dashboard::Platform - platform and shell helpers for Developer Dashboard

=head1 SYNOPSIS

  use Developer::Dashboard::Platform qw(
    native_shell_name
    shell_command_argv
    command_argv_for_path
  );

  my $shell = native_shell_name();
  my @cmd = shell_command_argv('git status');

=head1 DESCRIPTION

This module centralizes the small amount of operating-system and shell
awareness needed by Developer Dashboard so prompt integration, command
execution, and extension loading can work across Unix-style systems and
Windows Strawberry Perl installs.

=head1 FUNCTIONS

=head2 is_windows, native_shell_name, normalize_shell_name, shell_command_argv, command_in_path, is_runnable_file, resolve_runnable_file, command_argv_for_path, shell_quote_for

Platform and shell helpers used by the CLI and runtime.

=head2 passwd_user_name, passwd_home_directory

Guarded passwd database accessors. Windows perl leaves the passwd functions
unimplemented and dies when one is called, so both accessors report undef
instead of a fatal error whenever the current runtime cannot answer the lookup.
Callers use them as one step of an environment-first fallback chain.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module owns platform-specific command execution details. It resolves which file is runnable on the current operating system, decides how script paths should be turned into argv arrays, and smooths over Unix versus Windows command launch differences for the CLI and helper layers.

=head1 WHY IT EXISTS

It exists because command launch portability is a system concern. The dashboard has many staged helpers, hook scripts, skill commands, and Windows-oriented runners, and they all need one place that understands how to invoke a file correctly on the current host.

=head1 WHEN TO USE

Use this file when changing executable resolution, script-extension handling, PowerShell versus pwsh selection, or any bug where a helper runs on one platform but not another.

=head1 HOW TO USE

Call C<resolve_runnable_file>, C<is_runnable_file>, or C<command_argv_for_path> before launching a file. Higher-level code should pass the resulting argv into C<system>, C<exec>, or C<open3> instead of guessing the platform rules itself.

=head1 WHAT USES IT

It is used by C<bin/dashboard>, skill dispatch, hook execution, private helper staging, and platform-specific tests that cover Unix and Windows command launch semantics.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::Platform -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/07-core-units.t t/21-refactor-coverage.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
