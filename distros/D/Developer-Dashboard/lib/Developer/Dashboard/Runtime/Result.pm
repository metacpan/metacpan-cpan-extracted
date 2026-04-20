package Developer::Dashboard::Runtime::Result;

use strict;
use warnings;
use utf8;

our $VERSION = '2.72';

use Encode qw(encode);
use File::Basename qw(basename dirname);
use File::Temp qw(tempfile);
use Fcntl qw(F_GETFD F_SETFD FD_CLOEXEC SEEK_SET);
use JSON::XS qw(decode_json encode_json);

my %CHANNEL_FILE_HANDLE;
my %CHANNEL_FILE_PATH;

# current()
# Decodes the current RESULT environment variable into a hash reference.
# Input: none.
# Output: hash reference keyed by hook filename.
sub current {
    my $json = _channel_json( 'RESULT', 'RESULT_FILE' );
    return {} if !defined $json || $json eq '';
    my $data = decode_json($json);
    die 'RESULT must decode to a hash' if ref($data) ne 'HASH';
    return $data;
}

# set_current($data, %args)
# Serializes hook RESULT state back into the environment. Uses inline RESULT JSON
# while the payload stays small enough for safe exec(), then falls back to a
# file-backed RESULT_FILE channel when the payload grows too large.
# Input: hash reference of hook results plus an optional max_inline_bytes integer.
# Output: storage mode string: inline, file, or empty.
sub set_current {
    my ( $data, %args ) = @_;
    die 'RESULT state must be a hash' if ref($data) ne 'HASH';
    return clear_current() if !%{$data};
    return _set_channel( 'RESULT', 'RESULT_FILE', $data, %args );
}

# clear_current()
# Removes the active RESULT payload from both inline and file-backed channels.
# Input: none.
# Output: empty string.
sub clear_current {
    return _clear_channel( 'RESULT', 'RESULT_FILE' );
}

# last_result()
# Decodes the current LAST_RESULT environment variable into a hash reference.
# Input: none.
# Output: hash reference for the most recent hook result or undef.
sub last_result {
    shift if @_ && defined $_[0] && !ref($_[0]) && $_[0] eq __PACKAGE__;
    my $json = _channel_json( 'LAST_RESULT', 'LAST_RESULT_FILE' );
    return if !defined $json || $json eq '';
    my $data = decode_json($json);
    die 'LAST_RESULT must decode to a hash' if ref($data) ne 'HASH';
    return $data;
}

# set_last_result($data, %args)
# Serializes the most recent hook result into LAST_RESULT or LAST_RESULT_FILE.
# Input: hash reference describing the latest hook result plus an optional
# max_inline_bytes integer.
# Output: storage mode string: inline, file, or empty.
sub set_last_result {
    shift if @_ && defined $_[0] && !ref($_[0]) && $_[0] eq __PACKAGE__;
    my ( $data, %args ) = @_;
    die 'LAST_RESULT state must be a hash' if ref($data) ne 'HASH';
    return clear_last_result() if !%{$data};
    return _set_channel( 'LAST_RESULT', 'LAST_RESULT_FILE', $data, %args );
}

# clear_last_result()
# Removes the active LAST_RESULT payload from both inline and file-backed
# channels.
# Input: none.
# Output: empty string.
sub clear_last_result {
    shift if @_ && defined $_[0] && !ref($_[0]) && $_[0] eq __PACKAGE__;
    return _clear_channel( 'LAST_RESULT', 'LAST_RESULT_FILE' );
}

# stop_requested($stderr_or_hash)
# Detects the explicit hook stop marker emitted on stderr.
# Input: stderr string or a hash containing stderr/STDERR.
# Output: boolean flag.
sub stop_requested {
    shift if @_ && defined $_[0] && !ref($_[0]) && $_[0] eq __PACKAGE__;
    my ($value) = @_;
    my $stderr = '';
    if ( ref($value) eq 'HASH' ) {
        $stderr = defined $value->{STDERR}
          ? $value->{STDERR}
          : ( defined $value->{stderr} ? $value->{stderr} : '' );
    }
    elsif ( defined $value ) {
        $stderr = $value;
    }
    return $stderr =~ /\[\[STOP\]\]/ ? 1 : 0;
}

# names()
# Lists hook filenames currently stored in RESULT.
# Input: none.
# Output: sorted list of hook filename strings.
sub names {
    return sort keys %{ current() };
}

# has($name)
# Checks whether RESULT contains a record for a hook filename.
# Input: hook filename string.
# Output: boolean flag.
sub has {
    my ($name) = @_;
    return 0 if !defined $name || $name eq '';
    return exists current()->{$name} ? 1 : 0;
}

# entry($name)
# Returns the structured RESULT entry for one hook filename.
# Input: hook filename string.
# Output: hash reference or undef.
sub entry {
    my ($name) = @_;
    return if !defined $name || $name eq '';
    my $data = current();
    return $data->{$name};
}

# stdout($name)
# Returns captured stdout for one hook filename.
# Input: hook filename string.
# Output: stdout string or empty string.
sub stdout {
    my ($name) = @_;
    my $entry = entry($name);
    return '' if ref($entry) ne 'HASH' || !defined $entry->{stdout};
    return $entry->{stdout};
}

# stderr($name)
# Returns captured stderr for one hook filename.
# Input: hook filename string.
# Output: stderr string or empty string.
sub stderr {
    my ($name) = @_;
    my $entry = entry($name);
    return '' if ref($entry) ne 'HASH' || !defined $entry->{stderr};
    return $entry->{stderr};
}

# exit_code($name)
# Returns captured exit code for one hook filename.
# Input: hook filename string.
# Output: integer exit code or undef.
sub exit_code {
    my ($name) = @_;
    my $entry = entry($name);
    return if ref($entry) ne 'HASH';
    return $entry->{exit_code};
}

# last_name()
# Returns the last sorted hook filename currently present in RESULT.
# Input: none.
# Output: hook filename string or undef.
sub last_name {
    my @names = names();
    return $names[-1];
}

# last_entry()
# Returns the structured RESULT entry for the last sorted hook filename.
# Input: none.
# Output: hash reference or undef.
sub last_entry {
    my $name = last_name();
    return entry($name);
}

# report(%args)
# Builds a compact command hook report from the current RESULT payload.
# Input: optional command name override.
# Output: UTF-8 encoded formatted multi-line report string.
sub report {
    shift if @_ && defined $_[0] && !ref($_[0]) && $_[0] eq __PACKAGE__;
    my (%args) = @_;
    my @names = names();
    return '' if !@names;

    my $command = defined $args{command} && $args{command} ne ''
      ? $args{command}
      : _command_name();

    my @lines = (
        '----------------------------------------',
        sprintf( '%s Run Report', $command ),
        '----------------------------------------',
    );

    for my $name (@names) {
        my $exit_code = exit_code($name);
        my $icon = defined $exit_code && $exit_code == 0 ? '✅' : '🚨';
        push @lines, sprintf( '%s %s', $icon, $name );
    }

    push @lines, '----------------------------------------';
    return encode( 'UTF-8', join( "\n", @lines ) . "\n" );
}

# _current_json()
# Loads the current RESULT payload from inline env JSON or the file-backed
# RESULT_FILE fallback used when exec() would overflow the kernel arg/env limit.
# Input: none.
# Output: JSON string or empty string.
sub _current_json {
    return _channel_json( 'RESULT', 'RESULT_FILE' );
}

# _max_inline_bytes(%args)
# Returns the maximum inline RESULT JSON size before file-backed fallback kicks
# in. This stays conservative so later exec() calls do not trip E2BIG.
# Input: optional max_inline_bytes override.
# Output: positive integer byte count.
sub _max_inline_bytes {
    my (%args) = @_;
    return $args{max_inline_bytes}
      if defined $args{max_inline_bytes} && $args{max_inline_bytes} =~ /\A\d+\z/;
    return $ENV{DEVELOPER_DASHBOARD_RESULT_INLINE_MAX}
      if defined $ENV{DEVELOPER_DASHBOARD_RESULT_INLINE_MAX}
      && $ENV{DEVELOPER_DASHBOARD_RESULT_INLINE_MAX} =~ /\A\d+\z/;
    return 65536;
}

# _open_result_file()
# Opens one inherited file descriptor that child hook/command exec() calls can
# read through RESULT_FILE without inflating the process environment.
# Input: none.
# Output: filehandle and portable fd-backed path string.
sub _open_channel_file {
    my ( $fh, $path ) = tempfile( 'dashboard-result-XXXXXX', TMPDIR => 1, UNLINK => 1 );
    binmode $fh, ':raw';

    my $flags = fcntl( $fh, F_GETFD, 0 );
    die "Unable to inspect RESULT file descriptor flags: $!" if !defined $flags;
    fcntl( $fh, F_SETFD, $flags & ~FD_CLOEXEC )
      or die "Unable to clear close-on-exec for RESULT file descriptor: $!";

    my $fd = fileno($fh);
    my $fd_path = -e "/dev/fd/$fd" ? "/dev/fd/$fd" : "/proc/self/fd/$fd";
    return ( $fh, $fd_path );
}

# _channel_json($env_name, $file_env_name)
# Loads one hook payload from inline env JSON or its file-backed fallback.
# Input: env var names for the inline and file-backed channels.
# Output: JSON string or empty string.
sub _channel_json {
    my ( $env_name, $file_env_name ) = @_;
    my $json = $ENV{$env_name};
    return $json if defined $json && $json ne '';

    my $path = $ENV{$file_env_name} || '';
    return '' if $path eq '';
    open my $fh, '<:raw', $path or die "Unable to read $env_name file $path: $!";
    local $/;
    my $file_json = <$fh>;
    close $fh or die "Unable to close $env_name file $path: $!";
    return defined $file_json ? $file_json : '';
}

# _set_channel($env_name, $file_env_name, $data, %args)
# Serializes one hash payload into an inline env var or a file-backed fallback.
# Input: env var names, hash payload, and optional max_inline_bytes integer.
# Output: storage mode string.
sub _set_channel {
    my ( $env_name, $file_env_name, $data, %args ) = @_;
    my $json = encode_json($data);
    if ( length($json) <= _max_inline_bytes(%args) ) {
        _clear_channel_file($file_env_name);
        $ENV{$env_name} = $json;
        delete $ENV{$file_env_name};
        return 'inline';
    }

    my ( $fh, $path ) = _open_channel_file();
    print {$fh} $json;
    truncate( $fh, tell($fh) ) or die "Unable to truncate $env_name file $path: $!";
    seek( $fh, 0, SEEK_SET ) or die "Unable to rewind $env_name file $path: $!";

    _clear_channel_file($file_env_name);
    $CHANNEL_FILE_HANDLE{$file_env_name} = $fh;
    $CHANNEL_FILE_PATH{$file_env_name}   = $path;
    delete $ENV{$env_name};
    $ENV{$file_env_name} = $path;
    return 'file';
}

# _clear_channel($env_name, $file_env_name)
# Removes one inline/file-backed hook payload channel from the environment.
# Input: env var names for the inline and file-backed channels.
# Output: empty string.
sub _clear_channel {
    my ( $env_name, $file_env_name ) = @_;
    delete $ENV{$env_name};
    delete $ENV{$file_env_name};
    _clear_channel_file($file_env_name);
    return '';
}

# _clear_channel_file($file_env_name)
# Releases one inherited file-backed payload handle.
# Input: file-backed env var name.
# Output: none.
sub _clear_channel_file {
    my ($file_env_name) = @_;
    return if !$CHANNEL_FILE_HANDLE{$file_env_name};
    close $CHANNEL_FILE_HANDLE{$file_env_name}
      or die "Unable to close result file handle for $CHANNEL_FILE_PATH{$file_env_name}: $!";
    delete $CHANNEL_FILE_HANDLE{$file_env_name};
    delete $CHANNEL_FILE_PATH{$file_env_name};
}

# _command_name()
# Resolves the current dashboard command name for RESULT reports.
# Derives the command name from $0 first, then falls back to
# DEVELOPER_DASHBOARD_COMMAND env var if $0 is not valid.
# Handles special case where $0 basename is 'run' (directory-backed custom command).
# Input: none.
# Output: short command name string.
sub _command_name {
    my $script = $0 || '';
    if ( $script eq '' ) {
        my $name = $ENV{DEVELOPER_DASHBOARD_COMMAND} || '';
        return $name if $name ne '';
        return 'dashboard';
    }

    my $normalized = $script;
    $normalized =~ s{[\\/]+\z}{} if $normalized !~ m{\A(?:[\\/]|[A-Za-z]:[\\/]?)\z};
    return 'dashboard' if $normalized eq '' || $normalized eq '/' || $normalized eq '\\' || $normalized =~ m{\A[A-Za-z]:[\\/]?\z};

    my $base = basename($normalized);
    return $base if $base ne '' && $base ne '/' && $base ne '\\' && $base ne 'run';

    my $parent = basename( dirname($normalized) );
    return $parent if $parent ne '' && $parent ne '/' && $parent ne '\\';

    my $name = $ENV{DEVELOPER_DASHBOARD_COMMAND} || '';
    return $name if $name ne '';
    return 'dashboard';
}

1;

__END__

=head1 NAME

Developer::Dashboard::Runtime::Result - helper accessors for dashboard hook RESULT JSON

=head1 SYNOPSIS

  use Developer::Dashboard::Runtime::Result;

  my $all    = Developer::Dashboard::Runtime::Result::current();
  my $mode   = Developer::Dashboard::Runtime::Result::set_current($all);
  my $stdout = Developer::Dashboard::Runtime::Result::stdout('00-first.pl');
  my $prev   = Developer::Dashboard::Runtime::Result::last_result();
  my $stop   = Developer::Dashboard::Runtime::Result::stop_requested($prev);
  my $last   = Developer::Dashboard::Runtime::Result::last_entry();
  Developer::Dashboard::Runtime::Result::clear_current();
  Developer::Dashboard::Runtime::Result::clear_last_result();

=head1 DESCRIPTION

This module decodes the hook-result payload populated by C<dashboard> command
hook execution. Small payloads stay inline in C<RESULT>. Oversized payloads
spill into C<RESULT_FILE> before later C<exec()> calls would hit the kernel
arg/env limit. The helper accessors hide that transport detail and provide one
consistent way to read per-hook stdout, stderr, exit codes, the immediate
previous hook result in C<LAST_RESULT>, and the explicit C<[[STOP]]> marker
contract from Perl hook scripts.

=head1 FUNCTIONS

=head2 current, set_current, clear_current, last_result, set_last_result, clear_last_result, stop_requested, names, has, entry, stdout, stderr, exit_code, last_name, last_entry, report

Decode, write, clear, and report the current hook-result payload, whether it is
stored inline in C<RESULT> or spilled into C<RESULT_FILE>. The same helpers
also manage the immediate previous-hook payload in C<LAST_RESULT> /
C<LAST_RESULT_FILE> and detect the explicit C<[[STOP]]> stderr marker.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module manages the structured C<RESULT> and C<LAST_RESULT> state passed
between command hooks and their final command target. It serializes hook
stdout, stderr, and exit codes, tracks the immediate previous hook in one
stable hash shape, decodes that state for later hooks, and transparently
spills oversized payloads into C<RESULT_FILE> or C<LAST_RESULT_FILE> when the
environment would become too large.

=head1 WHY IT EXISTS

It exists because hook chaining needs a transport format that is explicit and
portable. Encoding that state in one module keeps hook readers and writers
synchronized, makes the immediate previous-hook handoff predictable, gives the
runtime one explicit place to detect the C<[[STOP]]> marker, and avoids
argument-list failures when a long hook chain produces too much output for
C<ENV{RESULT}> alone.

=head1 WHEN TO USE

Use this file when changing hook result serialization, C<RESULT> versus
C<RESULT_FILE> overflow rules, C<LAST_RESULT> handoff behavior, or the stop
marker/reporting helpers used by command-hook scripts.

=head1 HOW TO USE

Use C<set_current>, C<set_last_result>, C<clear_current>,
C<clear_last_result>, and the decode/report helpers rather than manipulating
C<ENV{RESULT}> or C<ENV{LAST_RESULT}> by hand. Hook scripts should read
structured state through this module instead of parsing JSON blobs
themselves, and they should use C<stop_requested> when they need to react to
the explicit stop marker.

=head1 WHAT USES IT

It is used by C<bin/dashboard> command-hook priming, custom CLI hook scripts,
update hooks, skill hook dispatch, and tests that cover result overflow,
previous-hook chaining, and explicit stop-marker behavior.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::Runtime::Result -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  perl -MDeveloper::Dashboard::Runtime::Result -e 'print Developer::Dashboard::Runtime::Result::stop_requested("[[STOP]] from hook\n") ? "stop\n" : "go\n"'

Probe the explicit stop-marker contract directly from one Perl process.

Example 3:

  perl -MDeveloper::Dashboard::Runtime::Result -e 'my $last = Developer::Dashboard::Runtime::Result::last_result() || {}; print($last->{file} // "none", "\n")'

Inspect the immediate previous hook payload without parsing C<ENV{LAST_RESULT}>
manually.

Example 4:

  prove -lv t/21-refactor-coverage.t t/05-cli-smoke.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 5:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 6:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
