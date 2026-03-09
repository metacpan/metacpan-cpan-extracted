package Linux::Event::Pid;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.010';

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

Linux::Event::Pid - pidfd-backed process-exit subscriptions for Linux::Event::Reactor

=head1 SYNOPSIS

<<<<<<< HEAD
=======
  use v5.36;
  use Linux::Event;

  my $loop = Linux::Event->new( model => 'reactor' );

  my $pid = fork() // die "fork: $!";
  if ($pid == 0) { exit 42 }

>>>>>>> 1401c31 (prep for cpan and release, new tool added)
  my $sub = $loop->pid($pid, sub ($loop, $pid, $status, $data) {
    ...
  });

=head1 DESCRIPTION

C<Linux::Event::Pid> adapts Linux pidfds into the reactor loop. It opens a
pidfd using L<Linux::FD::Pid>, watches it like any other readable filehandle,
and invokes the callback when the target process exits.

Most users access it through C<< $loop->pid(...) >>.

=head1 CALLBACK ABI

Pid callbacks receive four arguments:

  $cb->($loop, $pid, $status, $data)

When C<reap =E<gt> 1> is in effect and the target is a child process,
C<$status> is the wait status value. Otherwise it may be C<undef>.

=head1 OPTIONS

Recognized subscription options:

=over 4

=item * C<data>

=item * C<reap>

=back

=head1 SUBSCRIPTIONS

The returned subscription object supports C<cancel>.

=head1 SEE ALSO

L<Linux::Event::Reactor>,
L<Linux::Event::Loop>,
L<Linux::FD::Pid>

=cut
