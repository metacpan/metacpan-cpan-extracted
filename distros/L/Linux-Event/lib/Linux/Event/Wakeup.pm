package Linux::Event::Wakeup;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.009';

use Carp qw(croak);
use Scalar::Util qw(weaken);
use Fcntl qw(F_GETFD F_SETFD FD_CLOEXEC);

# eventfd-backed wakeups for Linux::Event.
#
# Semantics contract (single-waker model):
# - Exactly one waker per loop (cached by Loop).
# - Lazily created on first use.
# - Never destroyed during loop lifetime.
# - The Loop installs an internal read watcher that drains the fd.
# - User code MUST NOT watch($waker->fh, ...) directly.
# - signal() is safe from any thread.
# - drain() is non-blocking and returns the coalesced count.

sub new ($class, %args) {
  my $loop = delete $args{loop};
  croak "loop is required" if !$loop;
  croak "unknown args: " . join(", ", sort keys %args) if %args;

  weaken($loop);

  return bless {
    loop => $loop,
    _fh  => undef,
  }, $class;
}

sub loop ($self) { return $self->{loop} }

sub fh ($self) {
  $self->_ensure_fd;
  return $self->{_fh};
}

sub signal ($self, $n = 1) {
  $self->_ensure_fd;

  $n = 1 if !defined $n;
  croak "signal() increment must be a positive integer" if $n !~ /\A\d+\z/ || $n < 1;

  my $fh = $self->{_fh} or croak "waker not initialized";

  my $ok = eval { $fh->add(int($n)); 1 };
  if (!$ok) {
    # add() will fail with EAGAIN if the counter would overflow in non-blocking mode.
    croak "eventfd add failed: $@" if $@;
    croak "eventfd add failed: $!";
  }

  return 1;
}

sub drain ($self) {
  $self->_ensure_fd;

  my $fh = $self->{_fh} or return 0;

  my $total = 0;
  while (1) {
    my $v = eval { $fh->get };
    if (!defined $v) {
      last if $!{EAGAIN} || $!{EWOULDBLOCK};
      die $@ if $@;
      last;
    }
    $total += $v;
  }

  return $total;
}

sub _ensure_fd ($self) {
  return if $self->{_fh};

  # External dependency for eventfd integration.
  # Loaded lazily so the core loop can run even when Linux::FD::Event
  # is not installed.
  eval { require Linux::FD::Event; 1 }
    or croak "Linux::FD::Event is required for waker() support: $@";

  # Non-blocking is critical for epoll integration; we drain to EAGAIN.
  my $fh = Linux::FD::Event->new(0, 'non-blocking');

  # Ensure CLOEXEC (Linux::FD::Event does not currently expose this flag).
  my $fd = fileno($fh);
  if (defined $fd) {
    my $cur = fcntl($fh, F_GETFD, 0);
    if (defined $cur) {
      fcntl($fh, F_SETFD, $cur | FD_CLOEXEC);
    }
  }

  $self->{_fh} = $fh;
  return;
}

1;

__END__

=head1 NAME

Linux::Event::Wakeup - eventfd-backed wakeups for Linux::Event

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event;

  my $loop  = Linux::Event->new;

  # Create once during initialization:
  my $waker = $loop->waker;

  # From another thread (or a forked child), wake the loop:
  $waker->signal;

=head1 DESCRIPTION

This module provides a minimal, Linux-native wakeup primitive for
L<Linux::Event> based on C<eventfd(2)>. It is intended to be used as a
building block for thread and process integration without adding policy to
the core loop.

The wakeup is implemented internally using C<eventfd(2)> and exposed to the
loop as a readable filehandle.

When created via C<< $loop->waker >>, the loop installs an internal watcher
that drains the wakeup fd automatically. This guarantees that
C<< $waker->signal >> (and C<< $loop->stop >> after waker creation) can
reliably wake a blocking backend wait.

The wakeup fd is reserved for loop wakeups and must not be watched directly
by user code.

=head1 SEMANTICS

The semantics contract for the single-waker model is:

=over 4

=item * Exactly one waker per loop (cached by C<< $loop->waker >>).

=item * Created lazily on first use; never destroyed during loop lifetime.

=item * The loop installs an internal read watcher that drains the wakeup fd.

=item * User code must not call C<< $loop->watch($waker->fh, ...) >>,
        as this would replace the loop's internal watcher and break wakeup semantics.

=item * C<signal()> is safe from any thread.

=item * C<drain()> is non-blocking and returns the coalesced count.

=back

=head1 METHODS

=head2 fh

  my $fh = $waker->fh;

Returns the readable filehandle for this eventfd.

=head2 signal

  $waker->signal;      # increment by 1
  $waker->signal($n);  # increment by $n

Increments the eventfd counter. Multiple signals coalesce in the kernel.

=head2 drain

  my $count = $waker->drain;

Drains the eventfd counter (non-blocking) and returns the total number of
signals coalesced since the last drain.

=head1 DEPENDENCIES

Wakeup support requires L<Linux::FD::Event> (part of the C<Linux::FD> distribution).
The dependency is loaded lazily so you can still use the core loop features
(timers and I/O watchers) without it.

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

Same terms as Perl itself.

=head1 VERSION

This document describes Linux::Event::Wakeup version 0.007.

=cut
