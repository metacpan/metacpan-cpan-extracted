package Linux::Event::Loop;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.010';

use Carp qw(croak);
use Linux::Event::Reactor ();
use Linux::Event::Proactor ();

use constant READABLE => 0x01;
use constant WRITABLE => 0x02;
use constant PRIO     => 0x04;
use constant RDHUP    => 0x08;
use constant ET       => 0x10;
use constant ONESHOT  => 0x20;
use constant ERR      => 0x40;
use constant HUP      => 0x80;

sub new ($class, %arg) {
  my $model   = delete $arg{model};
  my $backend = delete $arg{backend};

  croak "model is required and must be 'reactor' or 'proactor'" if !defined $model;

  my ($impl_class, $default_backend) = _resolve_model($model);
  $backend //= $default_backend;

  my $self = bless {
    model => $model,
    impl  => undef,
  }, $class;

  my %impl_arg = (%arg, backend => $backend);
  $impl_arg{loop} = $self if $model eq 'reactor';

  $self->{impl} = $impl_class->new(%impl_arg);
  return $self;
}


sub _resolve_model ($model) {
  return ('Linux::Event::Reactor', 'epoll')   if $model eq 'reactor';
  return ('Linux::Event::Proactor', 'uring')  if $model eq 'proactor';
  croak "unknown model '$model'";
}

sub model ($self) { return $self->{model} }
sub impl  ($self) { return $self->{impl} }

sub _delegate ($self, $method, @arg) {
  my $impl = $self->{impl};
  croak "loop model '$self->{model}' does not support $method()" if !$impl->can($method);
  return $impl->$method(@arg);
}

sub backend_name ($self) { return $self->_delegate('backend_name') }
sub clock        ($self) { return $self->_delegate('clock') }
sub is_running   ($self) { return $self->_delegate('is_running') }
sub run          ($self, @arg) { return $self->_delegate('run', @arg) }
sub run_once     ($self, @arg) { return $self->_delegate('run_once', @arg) }
sub stop         ($self, @arg) { return $self->_delegate('stop', @arg) }

# Reactor surface
sub timer   ($self, @arg) { return $self->_delegate('timer', @arg) }
sub backend ($self, @arg) { return $self->_delegate('backend', @arg) }
sub sched   ($self, @arg) { return $self->_delegate('sched', @arg) }
sub signal  ($self, @arg) { return $self->_delegate('signal', @arg) }
sub waker   ($self, @arg) { return $self->_delegate('waker', @arg) }
sub pid     ($self, @arg) { return $self->_delegate('pid', @arg) }
sub watch   ($self, @arg) { return $self->_delegate('watch', @arg) }
sub unwatch ($self, @arg) { return $self->_delegate('unwatch', @arg) }
sub cancel  ($self, @arg) { return $self->_delegate('cancel', @arg) }
sub after   ($self, @arg) { return $self->_delegate('after', @arg) }
sub at      ($self, @arg) { return $self->_delegate('at', @arg) }

# Proactor surface
sub read            ($self, @arg) { return $self->_delegate('read', @arg) }
sub write           ($self, @arg) { return $self->_delegate('write', @arg) }
sub recv            ($self, @arg) { return $self->_delegate('recv', @arg) }
sub send            ($self, @arg) { return $self->_delegate('send', @arg) }
sub accept          ($self, @arg) { return $self->_delegate('accept', @arg) }
sub connect         ($self, @arg) { return $self->_delegate('connect', @arg) }
sub shutdown        ($self, @arg) { return $self->_delegate('shutdown', @arg) }
sub close           ($self, @arg) { return $self->_delegate('close', @arg) }
sub live_op_count   ($self, @arg) { return $self->_delegate('live_op_count', @arg) }
sub drain_callbacks ($self, @arg) { return $self->_delegate('drain_callbacks', @arg) }

# Private watcher hooks used by Linux::Event::Watcher.
sub _watcher_update ($self, @arg) { return $self->_delegate('_watcher_update', @arg) }
sub _watcher_cancel ($self, @arg) { return $self->_delegate('_watcher_cancel', @arg) }

1;

__END__

=head1 NAME

Linux::Event::Loop - Selector and public front door for Linux::Event engines

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;

  my $reactor = Linux::Event::Loop->new(
    model   => 'reactor',
    backend => 'epoll',
  );

  my $proactor = Linux::Event::Loop->new(
    model   => 'proactor',
    backend => 'uring',
  );

<<<<<<< HEAD
=======
  my $loop = Linux::Event->new(
    model => 'reactor',
  );

>>>>>>> 1401c31 (prep for cpan and release, new tool added)
=head1 DESCRIPTION

C<Linux::Event::Loop> is the stable public front door for this distribution.
It does not implement the readiness engine or the completion engine itself.
Instead, it selects one of the engine classes and delegates the public API to
that implementation object.

The current engines are:

=over 4

=item * L<Linux::Event::Reactor>

=item * L<Linux::Event::Proactor>

=back

<<<<<<< HEAD
This split keeps the public constructor short while allowing the reactor and
proactor internals to evolve independently.

=======
>>>>>>> 1401c31 (prep for cpan and release, new tool added)
=head1 CONSTRUCTOR

=head2 new(%args)

Recognized selector arguments:

=over 4

=item * C<model>

Either C<reactor> or C<proactor>. This argument is required.

=item * C<backend>

A backend name or backend object appropriate to the selected model.

=back

Any remaining arguments are forwarded to the selected engine constructor.

=head1 COMMON METHODS

These methods are delegated for both models when supported:

=over 4

=item * C<backend_name>

=item * C<clock>

=item * C<is_running>

=item * C<run>

=item * C<run_once>

=item * C<stop>

=back

=head1 REACTOR METHODS

When the selected model is C<reactor>, the following methods are available
through the loop facade:

=over 4

=item * C<timer>

=item * C<backend>

=item * C<sched>

=item * C<signal>

=item * C<waker>

=item * C<pid>

=item * C<watch>

=item * C<unwatch>

=item * C<cancel>

=item * C<after>

=item * C<at>

=back

=head1 PROACTOR METHODS

When the selected model is C<proactor>, the following methods are available
through the loop facade:

=over 4

=item * C<read>

=item * C<write>

=item * C<recv>

=item * C<send>

=item * C<accept>

=item * C<connect>

=item * C<shutdown>

=item * C<close>

=item * C<after>

=item * C<at>

=item * C<live_op_count>

=item * C<drain_callbacks>

=back

If a method is not supported by the selected model, the loop croaks with a
clear delegation error.

=head1 MODEL-SPECIFIC BEHAVIOR

This module does not try to erase the semantic difference between readiness and
completion I/O. It only gives both engines a common entry point.

For readiness semantics, see L<Linux::Event::Reactor>.
For completion semantics, see L<Linux::Event::Proactor>.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Reactor>,
L<Linux::Event::Proactor>

=cut
