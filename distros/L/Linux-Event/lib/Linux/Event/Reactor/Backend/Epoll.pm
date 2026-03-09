package Linux::Event::Reactor::Backend::Epoll;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.010';

use Carp qw(croak);
use Linux::Epoll;

use constant READABLE => 0x01;
use constant WRITABLE => 0x02;
use constant PRIO     => 0x04;
use constant RDHUP    => 0x08;
use constant ET       => 0x10;
use constant ONESHOT  => 0x20;
use constant ERR      => 0x40;
use constant HUP      => 0x80;

sub new ($class, %args) {
  # Optional backend defaults (not part of Loop's public API):
  my $edge    = delete $args{edge};
  my $oneshot = delete $args{oneshot};
  croak "unknown args: " . join(", ", sort keys %args) if %args;

  my $ep = Linux::Epoll->new;

  return bless {
    ep      => $ep,
    watch   => {},  # fd -> { fh, cb, mask, tag, loop }
    edge    => $edge ? 1 : 0,
    oneshot => $oneshot ? 1 : 0,
  }, $class;
}

sub name ($self) { return 'epoll' }

sub watch ($self, $fh, $mask, $cb, %opt) {
  croak "fh is required" if !$fh;
  croak "mask is required" if !defined $mask;
  croak "cb is required" if !$cb;
  croak "cb must be a coderef" if ref($cb) ne 'CODE';

  my $fd = fileno($fh);
  croak "fh has no fileno" if !defined $fd;
  $fd = int($fd);

  croak "fd already watched: $fd" if exists $self->{watch}{$fd};

  my $events = _mask_to_events($self, $mask);

  my $loop = $opt{_loop};
  my $tag  = $opt{tag};

  $self->{ep}->add($fh, $events, sub ($ev) {
    my $m = _events_to_mask($ev);
    $cb->($loop, $fh, $fd, $m, $tag);
  });

  $self->{watch}{$fd} = {
    fh   => $fh,
    cb   => $cb,
    mask => int($mask),
    tag  => $tag,
    loop => $loop,
  };

  return $fd;
}

sub modify ($self, $fh_or_fd, $mask, %opt) {
  croak "mask is required" if !defined $mask;

  my $fd = ref($fh_or_fd) ? fileno($fh_or_fd) : $fh_or_fd;
  return 0 if !defined $fd;
  $fd = int($fd);

  my $w = $self->{watch}{$fd} or return 0;

  my $loop = exists $opt{_loop} ? $opt{_loop} : $w->{loop};
  my $tag  = exists $opt{tag}   ? $opt{tag}   : $w->{tag};

  $w->{loop} = $loop;
  $w->{tag}  = $tag;

  my $new_mask = int($mask);
  my $old_mask = int($w->{mask});

  $w->{mask} = $new_mask;

  my $events = _mask_to_events($self, $new_mask);


  # EPOLLONESHOT rearm:
  # Rearming must be possible from inside a callback. Linux::Epoll's callback
  # dispatch is not guaranteed to be safe against a delete+add cycle performed
  # re-entrantly from within the callback. So for oneshot, prefer a real MOD.
  #
  # We still need to ensure a MOD happens even if the effective event set is
  # unchanged; Linux::Epoll->modify performs epoll_ctl(MOD) and does not elide
  # "no-op" masks.
  my $need_oneshot = (($new_mask & ONESHOT) || ($old_mask & ONESHOT) || $self->{oneshot}) ? 1 : 0;

  if ($self->{ep}->can('modify')) {
    $self->{ep}->modify($w->{fh}, $events, sub ($ev) {
      my $m = _events_to_mask($ev);
      $w->{cb}->($loop, $w->{fh}, $fd, $m, $tag);
    });
    return 1;
  }

  # Fallback: delete and re-add
  $self->{ep}->delete($w->{fh});
  $self->{ep}->add($w->{fh}, $events, sub ($ev) {
    my $m = _events_to_mask($ev);
    $w->{cb}->($loop, $w->{fh}, $fd, $m, $tag);
  });

  return 1;
}


sub unwatch ($self, $fh_or_fd) {
  my $fd = ref($fh_or_fd) ? fileno($fh_or_fd) : $fh_or_fd;
  return 0 if !defined $fd;
  $fd = int($fd);

  my $w = $self->{watch}{$fd} or return 0;
  $self->{ep}->delete($w->{fh});
  delete $self->{watch}{$fd};
  return 1;
}

sub run_once ($self, $loop, $timeout_s = undef) {
  my $max = 256;

  # Linux::Epoll->wait($number, $timeout) uses fractional seconds.
  # Keep $timeout_s in seconds (possibly fractional). undef => block, 0 => poll.
  my $ret = $self->{ep}->wait($max, $timeout_s);

  return 0 if !defined $ret;
  return $ret;
}


sub _mask_to_events ($self, $mask) {
  $mask = int($mask);
  my @ev;

  push @ev, 'in'    if ($mask & READABLE);
  push @ev, 'out'   if ($mask & WRITABLE);
  push @ev, 'prio'  if ($mask & PRIO);
  push @ev, 'rdhup' if ($mask & RDHUP);

  my %have = map { $_ => 1 } @ev;
  push @ev, 'et'      if (($mask & ET)      || ($self->{edge}    && !$have{et}));
  push @ev, 'oneshot' if (($mask & ONESHOT) || ($self->{oneshot} && !$have{oneshot}));

  return \@ev;
}

sub _events_to_mask ($ev) {
  my $m = 0;
  $m |= READABLE if $ev->{in};
  $m |= WRITABLE if $ev->{out};
  $m |= PRIO     if $ev->{prio};
  $m |= RDHUP    if $ev->{rdhup};
  $m |= ET       if $ev->{et};
  $m |= ONESHOT  if $ev->{oneshot};
  $m |= ERR      if $ev->{err};
  $m |= HUP      if $ev->{hup};
  return $m;
}

1;

1;

__END__

=head1 NAME

Linux::Event::Reactor::Backend::Epoll - epoll backend for Linux::Event::Reactor

=head1 SYNOPSIS

  # Usually constructed internally by Linux::Event::Reactor.
  my $backend = Linux::Event::Reactor::Backend::Epoll->new;

=head1 DESCRIPTION

C<Linux::Event::Reactor::Backend::Epoll> is the built-in readiness backend for
L<Linux::Event::Reactor>. It translates the reactor bitmask into the event set
expected by L<Linux::Epoll> and translates native epoll notifications back into
reactor masks.

=head1 CONSTRUCTOR

=head2 new(%args)

Recognized optional arguments:

=over 4

=item * C<edge>

Enable edge-triggered mode by default for all registrations.

=item * C<oneshot>

Enable one-shot mode by default for all registrations.

=back

=head1 METHODS

=head2 name

Returns C<epoll>.

=head2 watch($fh, $mask, $cb, %opt)

Register a filehandle with epoll and install the standardized reactor callback.
Returns the integer file descriptor.

=head2 modify($fh_or_fd, $mask, %opt)

Modify an existing epoll registration. If the underlying C<Linux::Epoll>
instance provides C<modify>, it is used directly. Otherwise the backend falls
back to delete plus add.

This path is especially important for C<EPOLLONESHOT> rearm.

=head2 unwatch($fh_or_fd)

Remove an existing registration.

=head2 run_once($loop, $timeout_s = undef)

Call epoll wait once and dispatch readiness callbacks.

=head1 NOTES

This backend keeps a small registration table keyed by file descriptor so it can
preserve callback, tag, and loop information across C<modify> calls.

=head1 SEE ALSO

L<Linux::Event::Reactor>,
L<Linux::Event::Reactor::Backend>,
L<Linux::Epoll>

=cut
