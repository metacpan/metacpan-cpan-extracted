package Linux::Event::Operation;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);
our $VERSION = '0.010';

sub _new ($class, %arg) {
    croak 'loop is required' unless $arg{loop};
    croak 'kind is required' unless defined $arg{kind};

    if (exists $arg{callback} && defined $arg{callback} && ref($arg{callback}) ne 'CODE') {
        croak 'callback must be a coderef';
    }

    my $self = bless {
        loop             => $arg{loop},
        kind             => $arg{kind},
        data             => $arg{data},
        state            => 'pending',

        result           => undef,
        error            => undef,

        callback         => $arg{callback},
        callback_queued  => 0,
        callback_ran     => 0,
        detached         => 0,

        backend_token    => undef,
        cancel_requested => 0,
    }, $class;

    return $self;
}

sub loop         ($self) { return $self->{loop} }
sub kind         ($self) { return $self->{kind} }
sub data         ($self) { return $self->{data} }
sub state        ($self) { return $self->{state} }
sub result       ($self) { return $self->{result} }
sub error        ($self) { return $self->{error} }

sub is_pending   ($self) { return $self->{state} eq 'pending'   ? 1 : 0 }
sub is_done      ($self) { return $self->{state} eq 'done'      ? 1 : 0 }
sub is_cancelled ($self) { return $self->{state} eq 'cancelled' ? 1 : 0 }
sub is_terminal  ($self) { return $self->{state} ne 'pending'   ? 1 : 0 }

sub success ($self) {
    return ($self->{state} eq 'done' && !defined $self->{error}) ? 1 : 0;
}

sub failed ($self) {
    return ($self->{state} eq 'done' && defined $self->{error}) ? 1 : 0;
}

sub on_complete ($self, $cb) {
    croak 'callback is required' unless defined $cb;
    croak 'callback must be a coderef' unless ref($cb) eq 'CODE';
    croak 'callback already set' if $self->_has_callback;

    $self->{callback} = $cb;

    if ($self->is_terminal) {
        $self->_queue_callback_if_needed;
    }

    return $self;
}

sub cancel ($self) {
    return $self->{loop}->_cancel_op($self);
}

sub detach ($self) {
    $self->{detached} = 1;
    $self->{callback} = undef;
    $self->{data}     = undef;
    return $self;
}

sub _set_backend_token ($self, $token) {
    $self->{backend_token} = $token;
    return $self;
}

sub _backend_token ($self) {
    return $self->{backend_token};
}

sub _has_callback ($self) {
    return defined $self->{callback} ? 1 : 0;
}

sub _settle_success ($self, $result) {
    croak 'operation already terminal' if $self->is_terminal;

    $self->{state}  = 'done';
    $self->{result} = $result;
    $self->{error}  = undef;

    $self->_queue_callback_if_needed;
    return $self;
}

sub _settle_error ($self, $error) {
    croak 'operation already terminal' if $self->is_terminal;

    $self->{state}  = 'done';
    $self->{result} = undef;
    $self->{error}  = $error;

    $self->_queue_callback_if_needed;
    return $self;
}

sub _settle_cancelled ($self) {
    croak 'operation already terminal' if $self->is_terminal;

    $self->{state}  = 'cancelled';
    $self->{result} = undef;
    $self->{error}  = undef;

    $self->_queue_callback_if_needed;
    return $self;
}

sub _queue_callback_if_needed ($self) {
    return $self if $self->{detached};
    return $self unless $self->_has_callback;
    return $self if $self->{callback_queued};
    return $self if $self->{callback_ran};

    $self->{callback_queued} = 1;
    $self->{loop}->_enqueue_callback($self);

    return $self;
}

sub _run_callback ($self) {
    return $self if $self->{detached};
    return $self unless $self->_has_callback;
    return $self if $self->{callback_ran};

    my $cb   = $self->{callback};
    my $data = $self->{data};

    $self->{callback_queued} = 0;
    $self->{callback_ran}    = 1;

    $cb->($self, $self->{result}, $data);

    $self->_cleanup_after_callback;
    return $self;
}

sub _cleanup_after_callback ($self) {
    $self->{callback} = undef;
    $self->{data}     = undef;
    return $self;
}

1;

__END__

=head1 NAME

Linux::Event::Operation - In-flight operation object for Linux::Event::Proactor

=head1 SYNOPSIS

  my $op = $loop->read(
    fh          => $fh,
    len         => 4096,
    data        => $ctx,
    on_complete => sub ($op, $result, $ctx) {
      return if $op->is_cancelled;

      if ($op->failed) {
        warn $op->error->message;
        return;
      }

      my $state = $op->state;
      my $kind  = $op->kind;
      my $res   = $op->result;
    },
  );

  $op->cancel;

=head1 DESCRIPTION

C<Linux::Event::Operation> represents one in-flight action submitted through
L<Linux::Event::Proactor>. Users obtain operation objects from the proactor
loop; they are not normally constructed directly.

An operation carries its kind, state, result or error, optional user data, and
a deferred completion callback.

=head1 STATES

An operation begins in C<pending> and then settles exactly once into one of
these terminal states:

=over 4

=item * C<done>

The operation completed. Inspect C<success> or C<failed> to distinguish success
from failure.

=item * C<cancelled>

Cancellation won the race.

=back

=head1 METHODS

=head2 loop

Return the owning proactor.

=head2 kind

Return the operation kind, such as C<read>, C<send>, or C<timeout>.

=head2 data

Return the user data payload associated with the operation.

=head2 state

Return the state string.

=head2 result

Return the normalized success result, if any.

=head2 error

Return the L<Linux::Event::Error> object for failed operations.

=head2 is_pending

=head2 is_done

=head2 is_cancelled

Predicate helpers for state inspection.

=head2 success

True when the operation completed successfully.

=head2 failed

True when the operation completed with an error.

=head2 cancel

Request cancellation through the owning proactor.

=head1 CALLBACKS

The user callback, if one was supplied, is queued by the proactor and later run
with this ABI:

  $cb->($op, $result, $data)

Callbacks are never executed inline by the backend.

=head1 SEE ALSO

L<Linux::Event::Proactor>,
L<Linux::Event::Error>

=cut
