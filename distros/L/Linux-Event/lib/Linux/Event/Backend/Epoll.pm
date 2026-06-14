package Linux::Event::Backend::Epoll;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.012';

use Carp qw(croak);
use Linux::Event::XS ();

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

  my $ep = Linux::Event::XS::epoll_new();

  return bless {
    ep      => $ep, # XS epoll fd + reusable event buffer
    watch   => Linux::Event::XS::registry_new(), # fd -> XS backend watch record
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

  croak "fd already watched: $fd" if Linux::Event::XS::registry_get($self->{watch}, $fd);

  my $events = _mask_to_events($self, $mask);
  my $rec = Linux::Event::XS::backend_watch_new(
    'Linux::Event::XS::BackendWatch',
    $fd,
    $fh,
    $cb,
    int($mask),
    $opt{_loop},
    $opt{tag},
  );

  Linux::Event::XS::epoll_add($self->{ep}, $fd, $events);
  Linux::Event::XS::registry_set($self->{watch}, $fd, $rec);

  return $fd;
}


sub watch_watcher ($self, $fh, $mask, $watcher, %opt) {
  croak "fh is required" if !$fh;
  croak "mask is required" if !defined $mask;
  croak "watcher is required" if !$watcher;

  my $fd = fileno($fh);
  croak "fh has no fileno" if !defined $fd;
  $fd = int($fd);

  croak "fd already watched: $fd" if Linux::Event::XS::registry_get($self->{watch}, $fd);

  my $events = _mask_to_events($self, $mask);
  my $rec = Linux::Event::XS::backend_watch_new_watcher(
    'Linux::Event::XS::BackendWatch',
    $fd,
    $fh,
    $watcher,
    int($mask),
    $opt{_loop},
    $opt{tag},
  );

  Linux::Event::XS::epoll_add($self->{ep}, $fd, $events);
  Linux::Event::XS::registry_set($self->{watch}, $fd, $rec);

  return $fd;
}

sub modify ($self, $fh_or_fd, $mask, %opt) {
  croak "mask is required" if !defined $mask;

  my $fd = ref($fh_or_fd) ? fileno($fh_or_fd) : $fh_or_fd;
  return 0 if !defined $fd;
  $fd = int($fd);

  my $rec = Linux::Event::XS::registry_get($self->{watch}, $fd) or return 0;

  my $loop = exists $opt{_loop} ? $opt{_loop} : undef;
  my $tag  = exists $opt{tag}   ? $opt{tag}   : undef;
  Linux::Event::XS::backend_watch_set_loop_tag($rec, $loop, $tag)
    if exists($opt{_loop}) || exists($opt{tag});

  my $new_mask = int($mask);
  Linux::Event::XS::backend_watch_set_mask($rec, $new_mask);

  my $events = _mask_to_events($self, $new_mask);
  Linux::Event::XS::epoll_modify($self->{ep}, $fd, $events);
  return 1;
}

sub unwatch ($self, $fh_or_fd) {
  my $fd = ref($fh_or_fd) ? fileno($fh_or_fd) : $fh_or_fd;
  return 0 if !defined $fd;
  $fd = int($fd);

  my $rec = Linux::Event::XS::registry_get($self->{watch}, $fd) or return 0;
  Linux::Event::XS::epoll_delete($self->{ep}, $fd);
  Linux::Event::XS::registry_delete($self->{watch}, $fd);
  return 1;
}

sub run_once ($self, $loop, $timeout_s = undef) {
  # XS owns the epoll fd and reuses a fixed epoll_event buffer across waits.
  return Linux::Event::XS::epoll_wait_dispatch($self->{ep}, $self->{watch}, $timeout_s);
}

sub _mask_to_events ($self, $mask) {
  $mask = int($mask);
  $mask |= ET      if $self->{edge};
  $mask |= ONESHOT if $self->{oneshot};
  return $mask;
}

1;

__END__

=head1 NAME

Linux::Event::Backend::Epoll - Built-in XS epoll backend for Linux::Event

=head1 DESCRIPTION

C<Linux::Event::Backend::Epoll> is the built-in readiness backend used by
L<Linux::Event::Loop>. It owns the epoll file descriptor and uses private
L<Linux::Event::XS> helpers for kernel registration, reusable event storage,
fd-indexed backend records, and dispatch into loop-created watchers.

This module is part of the public distribution, but its internal object layout
is private. Code should interact with it through L<Linux::Event::Loop> or the
backend contract documented in L<Linux::Event::Backend>.

=head1 CONSTRUCTOR

=head2 new(%args)

Create an epoll backend. Optional backend defaults are:

=over 4

=item * C<edge>

Register watchers in edge-triggered mode by default.

=item * C<oneshot>

Register watchers in one-shot mode by default.

=back

Most users should construct a loop with C<Linux::Event-E<gt>new> instead of
constructing the backend directly.

=head1 METHODS

=head2 name

Returns C<epoll>.

=head2 watch($fh, $mask, $cb, %opt)

Register C<$fh> for the readiness mask documented in
L<Linux::Event::Backend/READINESS MASKS>. This method is primarily for custom
loop/backend integration and preserves the generic backend callback ABI:

  $cb->($loop, $fh, $fd, $mask, $tag)

=head2 watch_watcher($fh, $mask, $watcher, %opt)

Private fast path used by L<Linux::Event::Loop> for loop-created watchers. It
avoids allocating a Perl dispatch closure per watcher. This is not a stable
public API.

=head2 modify($fh_or_fd, $mask, %opt)

Update an existing registration.

=head2 unwatch($fh_or_fd)

Remove an existing registration.

=head2 run_once($loop, $timeout_s = undef)

Wait for readiness once and dispatch any ready backend records.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Loop>,
L<Linux::Event::Backend>,
L<Linux::Event::XS>

=cut
