package Developer::Dashboard::Platform;

use strict;
use warnings;

our $VERSION = '6.31';

use Exporter 'import';
use File::Basename qw(basename dirname);
use File::Copy qw(copy);
use File::Spec;
use File::Temp qw(tempdir tempfile);

our @EXPORT_OK = qw(
  is_windows
  native_shell_name
  normalize_shell_name
  shell_command_argv
  command_in_path
  command_in_path_direct
  is_runnable_file
  resolve_runnable_file
  command_argv_for_path
  shell_quote_for
  passwd_user_name
  passwd_home_directory
  is_real_windows
  effective_mode_octal
  windows_acl_is_owner_only
  windows_acl_set_owner_only
);

our $OS_NAME = $^O;
our $EXEC_LAUNCHER = sub { exec @_ };
our $SYSTEM_LAUNCHER = sub { system @_ };

# The real operating system, captured at load time. $OS_NAME above is a
# localizable package variable: tests set it to MSWin32 to simulate Windows
# on Linux (for shell argv, PowerShell quoting and the like). That simulation
# cannot extend to ACLs - icacls and Windows DACLs do not exist on Linux -
# so every function below that touches the real filesystem keys off this
# flag, never off is_windows(). Same pattern as
# Developer::Dashboard::GoRoutine's $_REAL_OS_IS_WINDOWS.
my $_REAL_OS_IS_WINDOWS = $^O eq 'MSWin32';

# is_windows()
# Detects whether the active Perl runtime is running on Windows.
# Input: none.
# Output: boolean true for Strawberry/Windows-style runtimes, false otherwise.
sub is_windows {
    return $OS_NAME eq 'MSWin32' ? 1 : 0;
}

# is_real_windows()
# Detects whether the process is really running on Windows, immune to the
# $OS_NAME simulation tests use. Use this (not is_windows()) for any branch
# that touches the real Windows filesystem or a Windows-only tool: a
# simulated Windows on Linux has no icacls and no DACL to read or set.
# Input: none.
# Output: boolean true only on a real Windows runtime, false otherwise.
sub is_real_windows {
    return $_REAL_OS_IS_WINDOWS ? 1 : 0;
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

# _capture($code)
# Runs $code with stdout and stderr captured, WITHOUT loading
# Capture::Tiny: the lightweight hot path (d2 ps1 / d2 paths) must never
# load it - t/30 guards this with a poison Capture/Tiny.pm - yet on real
# Windows the hot path genuinely invokes the ACL functions below (the
# runtime paths are secured during config load), and those need icacls
# output. A lazy `require Capture::Tiny` is NOT enough: the require
# itself is what the poison trips (solo #187). So the capture is done by
# redirecting the standard handles to temporary files and slurping them
# back, which is all Capture::Tiny does for this use. The returned exit
# value is the raw wait status ($?), exactly as
# Capture::Tiny::capture returns it: 0 on success, non-zero otherwise.
# Input: code reference.
# Output: the captured (stdout, stderr, exit status) list.
sub _capture {
    my ($code) = @_;

    # DD-597: the $code->() call below (typically a system/icacls launch)
    # sets the global $? as a side effect; without this guard that stays
    # set in the caller's process after this sub returns. The $rc = $?
    # read below reads the localized value, so the returned wait status
    # is unchanged.
    local $?;
    my ( $out_fh, $out_name ) = tempfile( UNLINK => 0 );
    my ( $err_fh, $err_name ) = tempfile( UNLINK => 0 );
    binmode $out_fh, ':raw';
    binmode $err_fh, ':raw';
    my ( $out, $err, $rc );
    my ( $saved_out, $saved_err );
    my $ok = eval {
        # Save the real handles, then dup the temp files onto fd 1/2.
        # This MUST be an explicit save/restore, not `local *STDOUT`
        # plus a reopen: on a localized glob the reopen can land on
        # a different fd, so Perl prints are captured but a spawned
        # child still inherits the original fd 1 (proven by probe).
        open $saved_out, '>&', \*STDOUT or die "Unable to save stdout for capture: $!";
        open $saved_err, '>&', \*STDERR or die "Unable to save stderr for capture: $!";
        open STDOUT, '>&', $out_fh or die "Unable to redirect stdout for capture: $!";
        open STDERR, '>&', $err_fh or die "Unable to redirect stderr for capture: $!";
        $code->();
        $rc = $?;
        1;
    };
    my $error = $@;
    # Restore unconditionally, even when $code died, so the caller's
    # handles are never left pointing at the temp files.
    if ( defined $saved_out ) {
        open STDOUT, '>&', $saved_out or warn "Unable to restore stdout after capture: $!";
        close $saved_out;
    }
    if ( defined $saved_err ) {
        open STDERR, '>&', $saved_err or warn "Unable to restore stderr after capture: $!";
        close $saved_err;
    }
    close $out_fh;
    close $err_fh;
    $out = _slurp_raw_file($out_name);
    $err = _slurp_raw_file($err_name);
    unlink $out_name;
    unlink $err_name;
    die $error if !$ok;
    return ( $out, $err, $rc );
}

# _slurp_raw_file($path)
# Reads one file back as raw bytes (no CRLF translation), so captured
# icacls output keeps the exact bytes the command wrote.
# Input: file path string.
# Output: file contents string, or '' when the file cannot be read.
sub _slurp_raw_file {
    my ($path) = @_;
    open my $fh, '<:raw', $path or return '';
    my $contents = do { local $/; <$fh> };
    close $fh;
    return defined $contents ? $contents : '';
}

# _windows_current_user()
# Resolves the current Windows account as the DOMAIN\user identity icacls
# prints. The environment names come first (a logon always sets them); whoami
# is the fallback for a service logon without them. whoami lower-cases the
# spelling, so callers must compare identities case-insensitively.
# Input: none.
# Output: DOMAIN\user string, or undef when neither source can answer.
sub _windows_current_user {
    if ( defined $ENV{USERNAME} && $ENV{USERNAME} ne '' ) {
        return defined $ENV{USERDOMAIN} && $ENV{USERDOMAIN} ne '' ? "$ENV{USERDOMAIN}\\$ENV{USERNAME}" : $ENV{USERNAME};
    }
    my ( $out, undef, $rc ) = _capture( sub { $SYSTEM_LAUNCHER->('whoami') } );
    return if $rc != 0;
    $out =~ s/\s+\z//;
    return $out ne '' ? $out : undef;
}

# _windows_icacls_aces($path)
# Reads one path's DACL through icacls and returns its access entries.
# icacls is used instead of a Win32 API binding because Win32::FileSecurity
# is not installed on Strawberry Perl and the raw advapi32 calls need
# hand-packed SID/ACL structs; icacls ships with every Windows and its ACE
# lines (identity and parenthesised flags) are not localised, so parsing
# them is stable. Only lines that parse as an ACE are collected; the
# "Successfully processed" trailer and any other text are ignored.
# Input: file or directory path string.
# Output: array reference of [identity, flags] pairs, or undef when icacls
# fails (including a missing path), meaning the ACL cannot be verified.
sub _windows_icacls_aces {
    my ($path) = @_;
    my ( $out, $err, $rc ) = _capture( sub { $SYSTEM_LAUNCHER->( 'icacls', $path ) } );
    return if $rc != 0;
    my @aces;
    for my $line ( split /\r?\n/, $out ) {
        $line =~ s/^\s+//;
        $line =~ s/\s+\z//;
        next if $line eq '';
        # The first line carries the path ahead of its first ACE; strip the
        # exact path passed in so a drive-letter colon can never be mistaken
        # for the ACE delimiter. Later lines hold one ACE each.
        if ( index( $line, $path ) == 0 ) {
            $line = substr( $line, length($path) );
            $line =~ s/^\s+//;
        }
        next if $line !~ /\A(.+?):((?:\([^)]*\))+)\z/;
        push @aces, [ $1, $2 ];
    }
    return \@aces;
}

# windows_acl_is_owner_only($path)
# Checks whether one path's Windows DACL grants access to the current user
# only, with full control. The check is strict on purpose: any ACE for
# another identity, any inherited ACE, any deny or no-access ACE, any ACE
# without full control, and (for directories) any ACE missing the
# container/object inherit flags all fail it, because each one leaves a
# way in for someone other than the owner or lets a future child escape.
# Input: file or directory path string.
# Output: 1 when the DACL is owner-only, 0 when it is not, undef when the
# ACL cannot be verified (missing path, unknown user, icacls failure).
# Non-Windows callers get undef: this is a Windows-only check.
sub windows_acl_is_owner_only {
    my ($path) = @_;
    return if !defined $path || $path eq '' || !-e $path;
    return if !is_real_windows();
    my $user = _windows_current_user();
    return if !defined $user;
    my $aces = _windows_icacls_aces($path);
    return if !defined $aces;
    return 0 if !@$aces;
    my $is_dir = -d $path ? 1 : 0;
    for my $ace (@$aces) {
        my ( $identity, $flags ) = @$ace;
        return 0 if lc($identity) ne lc($user);
        return 0 if $flags =~ /\(I\)/ || $flags =~ /\(DENY\)/i || $flags =~ /\(IO\)/ || $flags =~ /\(N\)/;
        return 0 if $flags !~ /\(F\)/;
        return 0 if $is_dir && ( $flags !~ /\(OI\)/ || $flags !~ /\(CI\)/ );
    }
    return 1;
}

# windows_acl_set_owner_only($path)
# Replaces one path's Windows DACL with a single full-control ACE for the
# current user and disables inheritance, so no other account keeps access
# through an inherited entry. Directories get container/object inherit
# flags so children created inside inherit the same owner-only DACL.
# Input: file or directory path string.
# Output: the path string. Dies when the user cannot be determined or
# icacls fails, with the icacls output attached so the failure is diagnosable.
sub windows_acl_set_owner_only {
    my ($path) = @_;
    die "Missing path for Windows owner-only ACL\n" if !defined $path || $path eq '';
    my $user = _windows_current_user();
    die "Unable to determine the current Windows user for owner-only ACL on $path\n" if !defined $user;
    my $grant = -d $path ? "$user:(OI)(CI)F" : "$user:F";
    my ( $out, $err, $rc ) = _capture( sub { $SYSTEM_LAUNCHER->( 'icacls', $path, '/inheritance:r', '/grant:r', $grant ) } );
    die sprintf "Unable to set owner-only ACL on %s: icacls exited %d: %s%s\n", $path, $rc, $out, $err if $rc != 0;
    return $path;
}

# effective_mode_octal($path)
# Returns the permission bits for one file-system entry in four-digit octal
# form, in the terms the product's owner-only policy understands on this
# platform. On Unix that is the stat mode, unchanged. On Windows stat mode
# bits do not reflect ACLs (a file stays 0666 whatever its DACL says), so
# the mode is derived from the DACL instead: owner-only maps to 0700 for a
# directory, and to 0700 for an executable file or 0600 otherwise - the
# same -x rule the doctor's expected mode uses, so the two can never
# disagree. A path whose DACL is not owner-only reports its stat mode, so
# a loose path still reads loose and still gets flagged.
# Input: file or directory path string.
# Output: four-digit octal mode string or undef when stat fails.
sub effective_mode_octal {
    my ($path) = @_;
    my @stat = stat($path);
    return undef if !@stat;
    return sprintf '%04o', $stat[2] & 07777 if !is_real_windows();
    return sprintf '%04o', $stat[2] & 07777 if !windows_acl_is_owner_only($path);
    return '0700' if -d $path;
    return -x $path ? '0700' : '0600';
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
    $shell =~ s{.*[\\/]}{};
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

    my $shell = normalize_shell_name( $args{shell} || native_shell_name() );
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

    # DD-765 follow-up: File::Spec::Win32::path() prepends '.' to the list,
    # and File::Spec rewrites empty PATH entries to '.' on Unix, so without
    # this guard the caller's cwd is searched as if it were on PATH - the
    # same dot-in-PATH hazard the bare-name check above was written to
    # close, reached through the platform path list instead.
    for my $dir ( File::Spec->path ) {
        next if !defined $dir || $dir eq '';
        next if $dir eq '.' || File::Spec->canonpath($dir) eq '.';
        for my $candidate ( _path_candidates( File::Spec->catfile( $dir, $name ) ) ) {
            return $candidate if -f $candidate;
        }
    }

    return;
}

# command_in_path_direct($name)
# Resolves a bare command name from PATH to a file the native process spawn
# can execute directly. On Windows only .exe/.com/.bat/.cmd candidates
# count: an extensionless POSIX script is NOT returned, even though it is
# a file on PATH, because neither CreateProcess nor cmd can execute it -
# handing it to a bare system() call fails with rc 65280 (t/05 tests
# 694/696: the fake vim). A bare name carrying a path separator is not a
# PATH lookup at all and returns undef. On Unix this is command_in_path:
# any executable file on PATH runs.
# Input: bare command name.
# Output: absolute executable path string or undef when not found.
sub command_in_path_direct {
    my ($name) = @_;
    return if !defined $name || $name eq '';
    return if $name =~ m{[\\/]};
    return command_in_path($name) if !is_windows();

    for my $dir ( File::Spec->path ) {
        next if !defined $dir || $dir eq '';
        next if $dir eq '.' || File::Spec->canonpath($dir) eq '.';
        for my $candidate ( _path_candidates( File::Spec->catfile( $dir, $name ) ) ) {
            next if $candidate !~ /\.(?:com|exe|bat|cmd)\z/i;
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
        # The simulated platform cannot change the real filesystem: on
        # real Windows -x is extension-based, so a script file fails it
        # even when the dashboard can run it through an interpreter. When
        # the simulated platform says Linux but the real OS is Windows,
        # accept what the real platform can run. This line cannot fire on
        # real Linux (is_real_windows() is false) or in production on real
        # Windows (is_windows() is true there); it only repairs the
        # simulation, where the caller localized $OS_NAME to 'linux'.
        return $candidate if !is_windows() && is_real_windows() && _is_windows_runnable_candidate($candidate);
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

    # DD-856: an actual shebang line, when present, names the interpreter the
    # file's author intended - it must be honoured BEFORE any extension-based
    # guess. Without this check first, a shell script saved with a .pl suffix
    # (or any other mismatched extension) was silently force-run through the
    # wrong interpreter by extension alone, producing undefined behaviour
    # instead of running the script or reporting a clear error.
    if ( !is_windows() && _has_shebang($resolved) ) {
        return ( $^X, '-I', _module_lib_root(), $resolved ) if _shebang_uses_perl($resolved);
        return ($resolved);
    }

    # On Windows, extensionless POSIX skill scripts cannot be executed by
    # CreateProcess using their Unix shebang. Only route recognized shell
    # interpreters through an installed POSIX shell; keep Perl shebangs on
    # native Strawberry Perl and never execute arbitrary shebang commands.
    if ( is_windows() && _has_shebang($resolved) ) {
        return ( $^X, $resolved ) if _shebang_uses_perl($resolved);
        open my $shebang_fh, '<', $resolved
          or die "Unable to read $resolved: $!";
        my $first_line = <$shebang_fh> // '';
        close $shebang_fh or die "Unable to close $resolved: $!";
        if ( $first_line =~ m{\A\#!\s*(?:/usr/bin/env\s+|/bin/)(sh|bash)(?:\s|\z)} ) {
            my $shell = _posix_shell_binary($1);
            return ( $shell, _path_for_posix_shell( $shell, $resolved ) );
        }
    }

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
    # PATHEXT expansion is a real-filesystem concern: the candidates feed
    # -f checks, so they must follow the real OS, not the simulated one.
    # On real Windows the variants are needed even when the caller
    # localized $OS_NAME to 'linux' - without them command_in_path('node')
    # cannot find node.exe although it is on PATH (t/07 test 170, solo
    # #154). The gate still honors the simulation on Linux, where
    # is_real_windows() is false and nothing changes.
    return @candidates if !is_windows() && !is_real_windows();
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
    return 1 if $path =~ /\.go\z/i;
    return 1 if $path =~ /\.java\z/i;
    return 1 if $path =~ /\.(?:com|exe|bat|cmd)\z/i;
    return 1 if $path =~ /\.(?:sh|bash)\z/i && ( command_in_path('bash') || command_in_path('sh') || _git_for_windows_shell('sh') );
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
    return command_in_path($preferred)
      || command_in_path('sh')
      || _git_for_windows_shell($preferred)
      || _git_for_windows_shell('sh')
      || $preferred;
}

# _git_for_windows_shell($preferred)
# Resolves a POSIX shell from a Git for Windows install, if one is present.
# Git for Windows ships sh.exe and bash.exe in <root>\usr\bin, but that
# directory is not on PATH, so a plain PATH lookup never finds them and
# every shell-script invocation failed with 'sh' is not recognized.
# Input: preferred shell name such as sh or bash.
# Output: absolute shell path string, or undef.
sub _git_for_windows_shell {
    my ($preferred) = @_;
    for my $root ( _git_for_windows_roots() ) {
        my $shell = File::Spec->catfile( $root, 'usr', 'bin', "$preferred.exe" );
        return $shell if -f $shell;
    }
    return;
}

# _git_for_windows_roots()
# Lists candidate Git for Windows install roots: the install that owns the
# git on PATH, plus the conventional %ProgramFiles% locations. A candidate
# only counts when it actually contains usr/bin/sh.exe.
# Input: none.
# Output: install-root path strings.
sub _git_for_windows_roots {
    my @roots;
    my %seen;
    my $git = command_in_path('git');
    if ( defined $git && $git ne '' ) {
        my ( $volume, $dirs ) = File::Spec->splitpath($git);
        my @parts = grep { $_ ne '' } File::Spec->splitdir($dirs);
        # git.exe lives in <root>\cmd, <root>\bin or <root>\mingw64\bin.
        pop @parts while @parts && $parts[-1] =~ /\A(?:cmd|bin|mingw64|mingw32)\z/i;
        my $root = File::Spec->catdir( $volume . File::Spec->rootdir(), @parts );
        push @roots, $root if !$seen{$root}++;
    }
    for my $program_files ( grep { defined && $_ ne '' } $ENV{ProgramFiles}, $ENV{'ProgramFiles(x86)'} ) {
        my $root = File::Spec->catdir( $program_files, 'Git' );
        push @roots, $root if !$seen{$root}++;
    }
    return grep { -f File::Spec->catfile( $_, 'usr', 'bin', 'sh.exe' ) } @roots;
}

# _is_msys_shell($binary)
# Detects whether one resolved shell binary is an MSYS shell (Git for
# Windows), which spells Windows paths /c/... . A Cygwin or other sh lives
# elsewhere and must not get the MSYS spelling.
# Input: resolved shell binary path string.
# Output: boolean true when the binary is a Git for Windows MSYS shell.
sub _is_msys_shell {
    my ($binary) = @_;
    return 0 if !defined $binary || $binary eq '';
    return $binary =~ m{[\\/]usr[\\/]bin[\\/](?:sh|bash)(?:\.exe)?\z}i ? 1 : 0;
}

# _path_for_posix_shell($shell, $path)
# Spells one native path the way the resolved POSIX shell expects it. An
# MSYS shell (Git for Windows) takes /c/... spellings; any other shell gets
# the native path unchanged, which both MSYS and Cygwin convert themselves.
# Input: resolved shell binary path plus native file path.
# Output: path string as the shell should receive it.
sub _path_for_posix_shell {
    my ( $shell, $path ) = @_;
    return $path if !_is_msys_shell($shell);
    my $msys = $path;
    $msys =~ s{\\}{/}g;
    $msys =~ s{\A([A-Za-z]):}{'/' . lc($1)}e;
    return $msys;
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
# caller happens to already be inside that directory tree (DD-825). When a
# go.mod is found, GOMODCACHE/GOCACHE are also pointed at that layer's own
# local/go-cache/ directory (DD-951) so two skills never share one global
# module/build cache, mirroring DD-823's per-pom Maven build and DD-824's
# per-skill venv. A skill with no go.mod is unaffected - the env vars are
# only set when a real module file was found.
# Input: Go source file path plus passthrough argv.
# Output: does not return on success; dies when exec fails.
sub _exec_go_source {
    my ( $path, @args ) = @_;
    die "Missing Go source path\n" if !defined $path || $path eq '';
    my $dir = dirname($path);
    my $go_mod = _find_layer_go_mod($dir);
    my ( $mod_cache, $build_cache );
    if ( defined $go_mod ) {
        my $cache_root = File::Spec->catdir( dirname($go_mod), 'local', 'go-cache' );
        $mod_cache   = File::Spec->catdir( $cache_root, 'mod' );
        $build_cache = File::Spec->catdir( $cache_root, 'build' );
    }
    local $ENV{GOMODCACHE} = $mod_cache   if defined $mod_cache;
    local $ENV{GOCACHE}    = $build_cache if defined $build_cache;
    $EXEC_LAUNCHER->( 'go', 'run', '-C', $dir, $path, @args ) or die "Unable to exec go run for $path: $!";
}

# _find_layer_go_mod($dir)
# Walks up from a Go source file's own directory looking for a sibling
# go.mod - the same per-layer walk pattern _find_layer_pom uses for
# config/pom.xml (DD-823), reused here rather than inventing a second
# convention. Unlike pom.xml, go.mod is Go's own idiomatic module root
# marker, so it is looked for directly beside the source tree, not under
# a config/ subdirectory.
# Input: starting directory path.
# Output: absolute go.mod path string, or undef when no layer has one.
sub _find_layer_go_mod {
    my ($dir) = @_;
    while (1) {
        my $go_mod = File::Spec->catfile( $dir, 'go.mod' );
        return $go_mod if -f $go_mod;
        my $parent = dirname($dir);
        last if $parent eq $dir;    # reached filesystem root
        $dir = $parent;
    }
    return undef;
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
    copy( $path, $staged_source ) or die "Unable to stage Java source $path as $staged_source: $!";

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

    my $dependency_classpath = do { local $/; <$fh> };
    close $fh;
    $dependency_classpath =~ s/\s+\z//;

    my $classes_dir = File::Spec->catdir( $layer_root, 'target', 'classes' );
    # The JVM splits -cp on ';' on Windows and ':' everywhere else, and mvn
    # writes its resolved classpath with the same platform separator. A ':'
    # join on Windows fuses the layer classes directory and the first
    # dependency into one unusable entry (and collides with drive letters).
    my $classpath_separator = is_windows() ? ';' : ':';
    my $classpath = $dependency_classpath eq '' ? $classes_dir : $classes_dir . $classpath_separator . $dependency_classpath;

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

=head2 is_real_windows

Real-OS Windows detection, immune to the C<$OS_NAME> simulation tests use.
Use this for any branch that touches the real Windows filesystem or a
Windows-only tool.

=head2 passwd_user_name, passwd_home_directory

Guarded passwd database accessors. Windows perl leaves the passwd functions
unimplemented and dies when one is called, so both accessors report undef
instead of a fatal error whenever the current runtime cannot answer the lookup.
Callers use them as one step of an environment-first fallback chain.

=head2 effective_mode_octal, windows_acl_is_owner_only, windows_acl_set_owner_only

Windows owner-only permissions through real ACLs. Unix mode bits do not exist
on Windows (chmod only toggles the read-only attribute and stat keeps
reporting 0777/0666), so the setter replaces the DACL with one full-control
ACE for the current user and disables inheritance, the checker reads the DACL
back through icacls, and the mode helper reports 0700/0600 from the DACL
instead of the meaningless stat bits. On Unix the mode helper is the stat mode
unchanged.

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

It is used by C<bin/d2>, skill dispatch, hook execution, private helper staging, and platform-specific tests that cover Unix and Windows command launch semantics.

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
