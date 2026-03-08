package Linux::Event::Pid;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.009';

use Carp qw(croak);
use Scalar::Util qw(weaken);
use POSIX ();
# Linux waitid(2) flags. POSIX.pm does not always expose WEXITED.
# On Linux, WEXITED is 0x00000004 (from <linux/wait.h>).
use constant _WEXITED => 4;

sub _wait_flags ($self) {
  my $wnohang = eval { POSIX::WNOHANG() };
  $wnohang = 1 if !defined $wnohang;  # WNOHANG is 1 on Linux

  my $wexited = eval { POSIX::WEXITED() };
  $wexited = _WEXITED if !defined $wexited;

  return $wexited | $wnohang;
}


# pidfd-backed process exit notifications for Linux::Event.
#
# This module is a thin adaptor over Linux::FD::Pid. It opens a pidfd and
# registers a normal watcher with the loop; core dispatch remains unchanged.

sub new ($class, %args) {
  my $loop = delete $args{loop};
  croak "loop is required" if !$loop;
  croak "unknown args: " . join(", ", sort keys %args) if %args;

  weaken($loop);

  return bless {
    loop     => $loop,
    by_pid   => {},   # pid -> entry
  }, $class;
}

sub loop ($self) { return $self->{loop} }

sub pid ($self, $pid, $cb, %opts) {
  croak "pid is required" if !defined $pid;
  croak "callback is required" if !$cb || ref($cb) ne 'CODE';

  my $data = delete $opts{data};
  my $reap = delete $opts{reap};
  $reap = 1 if !defined $reap;
  croak "unknown opts: " . join(", ", sort keys %opts) if %opts;

  croak "pid must be a positive integer" if $pid !~ /\A\d+\z/ || $pid < 1;

  # Replacement semantics per PID:
  if (my $old = $self->{by_pid}{$pid}) {
    $old->{sub}->cancel;
  }

  my $fh = $self->_open_pidfd($pid);

  my $entry = {
    pid  => $pid,
    fh   => $fh,
    cb   => $cb,
    data => $data,
    reap => $reap ? 1 : 0,
    sub  => undef,
    w    => undef,
  };

  my $sub = bless { _pid => $pid, _owner => $self, _active => 1 }, 'Linux::Event::Pid::Subscription';

  $entry->{sub} = $sub;

  # Watch pidfd like any other fd. pidfd becomes readable when the target exits.
  my $w = $self->{loop}->watch($fh,
    read  => sub ($loop, $watcher, $ud) { $self->_on_ready($pid) },
    error => sub ($loop, $watcher, $ud) { $self->_on_ready($pid) },
    data  => undef,
  );

  $entry->{w} = $w;
  $self->{by_pid}{$pid} = $entry;

  return $sub;
}

sub _open_pidfd ($self, $pid) {
  eval { require Linux::FD::Pid; 1 }
    or croak "Linux::FD::Pid is required for pid() support: $@";

  # The module accepts 'non-blocking' as a flag; we still use WNOHANG for waits
  # to guarantee we never block in dispatch.
  my $fh = Linux::FD::Pid->new($pid, 'non-blocking');
  return $fh;
}

sub _on_ready ($self, $pid) {
  my $entry = $self->{by_pid}{$pid} or return;

  # If the subscription has been canceled, ignore spurious readiness.
  return if !$entry->{sub} || !$entry->{sub}{_active};

  my $status;
  if ($entry->{reap}) {
    # Non-blocking: returns undef if not ready.
    my $ok = eval {
      $status = $entry->{fh}->wait($self->_wait_flags);
      1;
    };
    if (!$ok) {
      # Not our child, already reaped, or other waitid() failure.
      my $err = $@ || "$!";
      croak "pid() reap failed for pid $pid: $err";
    }

    # If wait returned undef, the process may not be fully ready yet.
    return if !defined $status;
  } else {
    $status = undef;
  }

  # Dispatch (strict ABI: always 4 args).
  my $cb = $entry->{cb};
  $cb->($self->{loop}, $pid, $status, $entry->{data});

  # One-shot: once the process has exited (and we've observed readiness),
  # tear down the subscription.
  $entry->{sub}->cancel;

  return;
}

package Linux::Event::Pid::Subscription;
use v5.36;
use strict;
use warnings;

sub cancel ($self) {
  return 0 if !$self->{_active};
  $self->{_active} = 0;

  my $owner = $self->{_owner} or return 1;
  my $pid   = $self->{_pid};

  my $entry = delete $owner->{by_pid}{$pid};
  return 1 if !$entry;

  # Unwatch first (idempotent in watcher).
  if (my $w = $entry->{w}) {
    $w->cancel;
  }

  # Drop pidfd handle (will close when refcount reaches zero).
  $entry->{fh} = undef;

  return 1;
}

1;

__END__

=head1 NAME

Linux::Event::Pid - pidfd-backed process exit notifications for Linux::Event

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event;

  my $loop = Linux::Event->new;

  my $pid = fork() // die "fork: $!";
  if ($pid == 0) { exit 42 }

  my $sub = $loop->pid($pid, sub ($loop, $pid, $status, $data) {
    $loop->stop;

    if (defined $status) {
      my $code = $status >> 8;
      say "child $pid exited with $code";
    }
  });

  $loop->run;

=head1 DESCRIPTION

This module integrates Linux pid file descriptors (pidfd) into L<Linux::Event>.
It opens a pidfd using L<Linux::FD::Pid> and watches it via epoll. When the
pidfd becomes readable, the callback is invoked.

This is a Linux-native alternative to C<SIGCHLD> wakeups. Exit status is only
available when the watched PID is a child of the current process.

=head1 CALLBACK SIGNATURE

  sub ($loop, $pid, $status, $data) { ... }

Exactly four arguments are passed. C<$status> is a raw wait status compatible
with the usual POSIX wait macros (e.g. C<WIFEXITED>, C<WEXITSTATUS>). If exit
status is unavailable, C<$status> is C<undef>.



=head1 SEMANTICS

=over 4

=item * One subscription per PID (replacement semantics).

Registering C<pid()> again for the same PID replaces the previous handler.

=item * One-shot delivery.

When the process exit is observed and a defined wait status is obtained (when
C<reap =E<gt> 1>), the callback is invoked once and the subscription is
automatically canceled.

=item * Reaping.

By default C<reap =E<gt> 1> and Linux::Event attempts a non-blocking wait via
C<< Linux::FD::Pid->wait(WEXITED|WNOHANG) >>. Exit status is only available for
child processes; if reaping fails (for example, because the PID is not a child),
an exception is thrown. Use C<reap =E<gt> 0> to receive an exit notification
without attempting to reap or obtain a status.

=item * Subscription cancellation is idempotent.

=back

=head1 METHODS

=head2 pid

  my $sub = $loop->pid($pid, $cb, %opts);

Registers a handler for the given C<$pid>. One handler per PID is allowed;
registering again replaces the previous handler.

Options:

=over 4

=item * data => $any

Optional user data passed to the callback.

=item * reap => 1|0

Defaults to 1. If true, Linux::Event attempts to reap the child using a
non-blocking wait and passes the wait status. If false, no wait is attempted
and C<$status> will be undef.

=back

The returned subscription supports C<< $sub->cancel >> which is idempotent.

=head1 DEPENDENCIES

Requires L<Linux::FD::Pid> and a kernel that supports C<pidfd_open(2)>.

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

Same terms as Perl itself.

=head1 VERSION

This document describes Linux::Event::Pid version 0.006.

=cut
