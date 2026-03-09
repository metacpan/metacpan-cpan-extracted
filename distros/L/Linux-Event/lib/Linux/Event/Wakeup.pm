package Linux::Event::Wakeup;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.010';

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

Linux::Event::Wakeup - eventfd-backed wakeup primitive for Linux::Event::Reactor

=head1 SYNOPSIS

  my $waker = $loop->waker;

<<<<<<< HEAD
  # from another thread or cooperating producer
  $waker->signal;
=======
  my $loop = Linux::Event->new( model => 'reactor' );
>>>>>>> 1401c31 (prep for cpan and release, new tool added)

  # in the loop
  my $count = $waker->drain;

=head1 DESCRIPTION

C<Linux::Event::Wakeup> provides an eventfd-backed wakeup mechanism for the
reactor. The usual pattern is to enqueue work elsewhere, then signal the waker
so the loop can wake promptly and drain that work source.

Most users obtain the waker through C<< $loop->waker >>. The reactor installs an
internal read watcher for the eventfd so stop and explicit wakeups can break a
blocking backend wait.

=head1 METHODS

=head2 fh

Return the eventfd-backed filehandle.

=head2 signal

Increment the wakeup counter.

=head2 drain

Drain pending wakeups and return the number observed.

=head1 SEE ALSO

L<Linux::Event::Reactor>,
L<Linux::Event::Loop>

=cut
