package MCP::Run::Bash;
our $VERSION = '0.107';
use Mojo::Base 'MCP::Run', -signatures;

# ABSTRACT: MCP server that executes commands via bash


use IPC::Open3;
use IO::Select;
use Symbol 'gensym';
use POSIX        ':sys_wait_h';
use Errno        'EINTR';
use Scalar::Util 'looks_like_number';

# Grace period (seconds) between SIGTERM and SIGKILL when a command times
# out, plus the poll interval used while waiting for the child to go away.
# Without the escalation a child that ignores SIGTERM blocks the server for
# as long as it feels like running.
use constant TERM_GRACE => 2;
use constant REAP_POLL  => 0.05;

# Last resort when neither the per-call timeout nor the server default is a
# usable positive number. Mirrors the MCP::Run timeout attribute default: a
# command must never run unbounded, that would pin the server indefinitely.
use constant FALLBACK_TIMEOUT => 30;

# alarm() hands its argument to a C unsigned int, and 2**31-1 is the largest
# value that arrives intact. Above it alarm() either warns about a negative
# argument or - from 2**32 on - quietly sets no alarm at all, which is the
# unbounded command all over again, only without a trace. Measured, not
# assumed; Inf gets here too, since it passes for a positive number.
use constant MAX_TIMEOUT => 2**31 - 1;

has name => 'mcp-run-bash';


has version => $VERSION;


sub execute ($self, $command, $working_directory, $timeout) {
  $timeout = $self->_effective_timeout($timeout);

  my ($stdout, $stderr) = ('', '');
  my ($exit_code, $error);

  eval {
    my $err = gensym;

    # The child reports a failed chdir through this pipe. Perl sets
    # close-on-exec on it, so a successful exec closes the write end and the
    # parent reads end-of-file; a failure leaves the reason behind.
    pipe(my $chdir_r, my $chdir_w) or die "pipe: $!\n";

    # open3 with '-' forks without exec'ing and returns 0 in the child, which
    # lets the child put itself into its own process group *before* exec.
    # Doing that from the parent loses a race: open3 only returns once the
    # child has exec'd, and setpgid() on an already exec'd child fails with
    # EACCES, leaving the command in our own group where it cannot be
    # signalled as a group.
    my $pid = open3(my $in, my $out, $err, '-');
    unless ($pid) {
      eval { setpgrp(0, 0) };    # best effort: not available everywhere
      close $chdir_r;

      # chdir here, not "cd DIR && COMMAND" in front of the command: the
      # prefix binds only to the first command of a list, so a command after
      # ';', a newline or '&' ran in the wrong directory, and when the cd
      # failed the rest of the list ran anyway, in the caller's. A directory
      # that cannot be entered stops here, before the command exists.
      if (defined $working_directory && length $working_directory
          && !chdir $working_directory) {
        syswrite $chdir_w, "cannot change to working directory '$working_directory': $!";
        POSIX::_exit(1);
      }
      exec 'bash', '-c', $command
        or print STDERR "mcp-run-bash: exec of bash failed: $!\n";
      POSIX::_exit(127);         # must never return into the parent program
    }
    close $in;
    close $chdir_w;

    my $select = IO::Select->new($out, $err);
    my $timed_out = 0;

    # The command has its own process group now, so a group kill aimed at us
    # no longer reaches it. Take the termination signals over for the
    # duration of the command, or a cancelled run would leave the command
    # behind after we are gone.
    #
    # Taking a signal over no longer stops at a signal the embedding program
    # has taken over itself. The command is stopped either way - a command
    # that outlives the run leaves work behind that nobody asked for - and
    # the signal is handed on afterwards, to the program's own handler,
    # chained once the command is gone. How the program shuts down is its
    # business; that the command does not outlive the run is ours.
    #
    # A signal the program ignores is left alone, program and command
    # alike: it asked for the signal to have no effect, and the command
    # inherits that disposition across the exec.
    my @forward = grep { !_signal_ignored($_) } qw(HUP INT TERM);
    my %previous = map { $_ => $SIG{$_} } @forward;
    my $child_status;
    local @SIG{@forward} = map {
      my $signal = $_;
      sub {
        # The timeout alarm must not abort the cleanup: a die from here
        # would skip the chaining and swallow the signal the program was
        # sent. The command is dead after this anyway, so the timeout has
        # nothing left to guard.
        local $SIG{ALRM} = sub { };

        # $? is global: a waitpid in here overwrites the status the main
        # flow is about to read. Keep it, and put it back unless this
        # handler reaped the child itself.
        my $saved = $?;
        my $status = _terminate($pid);
        if (defined $status) { $child_status = $status }
        else                 { $? = $saved }

        _chain_signal($signal, $previous{$signal});
      };
    } @forward;

    local $SIG{ALRM} = sub { $timed_out = 1; die "alarm\n" };
    alarm($timeout);

    my $status;
    eval {
      while ($select->count) {
        my @ready = $select->can_read;
        # can_read comes back empty when a signal interrupted the select, not
        # only at end of output. Looping on the handle count instead of on
        # can_read keeps that from cutting the output short; a select that
        # keeps failing is bounded by the alarm above.
        next unless @ready;
        for my $fh (@ready) {
          my $buf;
          my $bytes = sysread($fh, $buf, 4096);
          if (!defined $bytes) {
            # A signal interrupting the read is not end of output; treating
            # EINTR as EOF would silently truncate what the command wrote.
            next if $! == EINTR;
            $select->remove($fh);
            next;
          }
          if (!$bytes) {
            $select->remove($fh);
            next;
          }
          if ($fh == $out) { $stdout .= $buf }
          else             { $stderr .= $buf }
        }
      }

      # Reaped under the alarm on purpose: a command that closes its output
      # and keeps running - 'exec >/dev/null 2>&1; sleep 300' - reaches this
      # point immediately, and an unguarded waitpid would let it outrun its
      # timeout by as much as it liked.
      my $reaped = waitpid($pid, 0);
      $status = $reaped > 0 ? $? : $child_status;

      # A signal handler may have reaped the child already, in which case
      # the wait above finds nothing and the status was recorded there. If
      # nobody reaped it at all, the wait status is all there is - and it
      # says the child was not ours.
      $status = $? unless defined $status;
    };

    alarm(0);

    if ($timed_out) {
      _terminate($pid);
      $exit_code = 124;
      $error     = "Command timed out after ${timeout}s";
    }
    elsif (defined $status) {
      # A signalled child carries the signal number in the low byte and zero
      # in the high byte, so $? >> 8 alone would report success. Use the
      # shell convention instead.
      $exit_code = ($status & 127) ? 128 + ($status & 127) : $status >> 8;
    }

    close $out;
    close $err;

    # Nothing is written on success (the descriptor closes on exec), so a
    # message here means the command never started.
    my $chdir_error = '';
    unless ($timed_out) {
      my $got = sysread($chdir_r, $chdir_error, 4096);
      $chdir_error = '' unless $got;
    }
    close $chdir_r;
    if (length $chdir_error) {
      $exit_code = 1;
      $error     = $chdir_error;
    }
  };

  if ($@ && !defined $exit_code) {
    $exit_code = 1;
    $error     = "$@";
    chomp $error;
  }

  chomp $stdout;
  chomp $stderr;

  return { exit_code => $exit_code, stdout => $stdout, stderr => $stderr, (defined $error ? (error => $error) : ()) };
}


# Stop a timed out, cancelled or interrupted command: SIGTERM the group, then
# SIGKILL it if the grace period passes without the child being reaped.
# Returns the child's status if this call reaped it, and undef if the child
# was never there to reap - only the reaper gets to see the status.
sub _terminate ($pid) {
  _signal_group($pid, 'TERM');
  my $status = _reap_within_grace($pid);
  return $status if defined $status;
  _signal_group($pid, 'KILL');
  my $reaped = waitpid($pid, 0);
  return $reaped > 0 ? $? : undef;
}

# Hand the signal on to whoever was going to receive it. A handler of the
# embedding program is called, with the signal name, the way Perl itself
# would call it; a default disposition is re-raised, so the signal keeps the
# effect it usually has.
sub _chain_signal ($signal, $previous) {
  if (ref $previous) {
    $previous->($signal);
    return;
  }
  $SIG{$signal} = 'DEFAULT';
  kill $signal, $$;
}

# True while the embedding program has the signal ignored. Such a signal is
# left alone: the program asked for the signal to have no effect on it, and
# the command inherits the disposition across the exec, so taking the signal
# over would only make program and command disagree about it.
sub _signal_ignored ($signal) {
  my $handler = $SIG{$signal};
  return defined $handler && !ref $handler && $handler eq 'IGNORE';
}

# Signal the command's whole process group, falling back to the bare child
# when the group kill fails (setpgrp unsupported, or the child already gone).
sub _signal_group ($pid, $signal) {
  return kill($signal, -$pid) || kill($signal, $pid);
}

# Wait for the child to go away, but no longer than the grace period. Returns
# the child's status if it was reaped here, and undef while it is still
# running.
sub _reap_within_grace ($pid) {
  my $waited = 0;
  while ($waited < TERM_GRACE) {
    my $reaped = waitpid($pid, WNOHANG);
    return $? if $reaped > 0;
    select undef, undef, undef, REAP_POLL;
    $waited += REAP_POLL;
  }
  my $reaped = waitpid($pid, WNOHANG);
  return $reaped > 0 ? $? : undef;
}

# Timeouts alarm() cannot act on fall back to the server default, and then to
# FALLBACK_TIMEOUT, rather than disabling the alarm.
sub _effective_timeout ($self, $timeout) {
  my ($usable) = grep { _usable_timeout($_) } $timeout, $self->timeout, FALLBACK_TIMEOUT;

  # alarm() counts whole seconds, so half a second would become alarm(0) -
  # switching the timeout off instead of firing at once. Round that up, and
  # truncate the rest the way alarm() would, so the timeout reported back is
  # the one that actually ran.
  return $usable < 1 ? 1 : int($usable);
}

sub _usable_timeout ($value) {
  return 0 unless defined $value && looks_like_number($value);
  return 0 if $value != $value;                          # NaN
  return 0 unless $value > 0 && $value <= MAX_TIMEOUT;    # Inf fails this too
  return 1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MCP::Run::Bash - MCP server that executes commands via bash

=head1 VERSION

version 0.107

=head1 SYNOPSIS

    use MCP::Run::Bash;

    my $server = MCP::Run::Bash->new(
        allowed_commands  => ['ls', 'cat', 'grep'],
        working_directory => '/var/data',
        timeout           => 30,
    );
    $server->to_stdio;

=head1 DESCRIPTION

Concrete L<MCP::Run> subclass that executes commands by invoking
C<bash -c $command> via L<IPC::Open3>. Captures stdout and stderr separately,
enforces a per-command timeout using C<alarm>, and returns the exit code.

When a C<working_directory> is specified (either as a server default or
passed per-invocation), the child process changes into it with C<chdir>
before bash is started, so every part of the command - after C<;>, a newline
or a background C<&> - runs there. A directory that does not exist or cannot
be entered is an error: the command is not run, the exit code is C<1> and
C<error> says which directory and why.

The command runs in its own process group, so a timeout reaches the whole
process tree and not just the bash that was started. On timeout the process
group is sent C<SIGTERM>, escalated to C<SIGKILL> if it is still alive after
a two second grace period, and the exit code is set to C<124> (matching the
convention used by GNU C<timeout(1)>).

The same group is stopped when the program running the command is signalled:
C<SIGHUP>, C<SIGINT> and C<SIGTERM> are taken over for the duration of the
command, the group is sent C<SIGTERM> and then C<SIGKILL>, and the signal is
handed on afterwards to whoever was going to receive it. A program that
installed a handler of its own keeps it, and it runs once the command is
gone. A signal the program ignores is left alone, program and command alike.

A command killed by a signal reports C<128 + signal number>, the same
convention a shell uses: a build killed by the OOM killer comes back as
C<137>, not as a successful C<0>.

=head2 name

Server name reported to the MCP client in C<serverInfo>. Defaults to
C<mcp-run-bash>, overriding the C<PerlServer> default inherited from
L<MCP::Server>. Pass C<name> to the constructor to identify as something else.

=head2 version

Server version reported to the MCP client in C<serverInfo>. Defaults to this
distribution's version, overriding the C<1.0.0> default inherited from
L<MCP::Server>.

=head2 execute

    my $result = $self->execute($command, $working_directory, $timeout);

Implements L<MCP::Run/execute>. Runs C<$command> under C<bash -c>,
capturing stdout and stderr via L<IPC::Open3> and L<IO::Select>. If
C<$working_directory> is defined and not empty, the child C<chdir>s into it
first; if that fails the command is not executed and the result has exit code
C<1> and an C<error> of the form C<cannot change to working directory '...': reason>.

The timeout is enforced with C<alarm>. A C<$timeout> C<alarm> cannot act on
falls back to the server's C<timeout> attribute, and to C<30> seconds if that
is not usable either. C<0> deliberately does not mean "no timeout": an
unbounded command would occupy the server for as long as it runs. Rejected
are C<0>, negative values, C<undef>, non-numbers, C<NaN>, C<Inf>, and
anything above C<2**31-1> - past that C<alarm> stops being able to represent
the value and sets no alarm at all, in part without even warning.

Fractions are rounded to whole seconds, and never down to zero: C<alarm>
counts in seconds, so C<0.5> becomes one second rather than no timeout.

The timeout covers the whole command, not just the part of it that produces
output: a command that closes stdout and stderr and keeps running is timed
out like any other.

On expiry the command's process group is sent C<SIGTERM>; if it has not
exited within a two second grace period it is sent C<SIGKILL>. The exit code
is C<124> either way.

A command that exits normally reports its exit status. A command killed by a
signal reports C<128 + signal number> (C<137> for C<SIGKILL>, C<143> for
C<SIGTERM>), so a signalled command is never mistaken for a successful one.

While a command runs, C<SIGHUP>, C<SIGINT> and C<SIGTERM> are stopped on the
way past: the command is killed first, and the signal then continues on its
way. Without that, a kill aimed at the process calling C<execute> would leave
the command running in its own process group.

The signal continues as the calling program had it: a handler of its own is
chained, after the command is gone, so the program can still do what it meant
to do when the signal arrived; a default disposition is re-raised, so the
signal keeps the effect it usually has. What becomes of the program is the
program's business. That the command does not outlive the run is not: a
command that keeps running after the signal leaves work behind that nobody
asked for.

A signal the calling program ignores is left alone, in the program and in the
command alike: the program asked for the signal to have no effect, and the
command inherits the disposition across the exec. That is the one case in
which a command can outlive the signal that was aimed at the program running
it.

Returns a hashref with keys C<exit_code>, C<stdout>, C<stderr>, and
optionally C<error>.

Residual cases the process group does not cover: a descendant that leaves the
group on its own - a daemon calling C<setsid>, or anything started with
C<nohup ... &> that re-parents itself out - survives the kill, and on a
platform without C<setpgrp> only the bash itself is signalled, leaving its
children running. Both are reported as C<124> like any other timeout.

=head1 SEE ALSO

=over

=item * L<MCP::Run> - Base class defining the C<run> MCP tool

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-mcp-run/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
