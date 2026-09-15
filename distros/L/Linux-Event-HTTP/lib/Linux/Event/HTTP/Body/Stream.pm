package Linux::Event::HTTP::Body::Stream;
use v5.36;
use strict;
use warnings;

use Scalar::Util qw(weaken);

our $VERSION = '0.001';

sub _validated_options ($kind, %option) {
    die 'body stream kind must be request or response'
        if $kind ne 'request' && $kind ne 'response';

    my $on_drain  = delete $option{on_drain};
    my $on_cancel = delete $option{on_cancel};
    my $operation = $kind . '_body';

    die "$operation(): on_drain must be a coderef"
        if defined($on_drain) && ref($on_drain) ne 'CODE';
    die "$operation(): on_cancel must be a coderef"
        if defined($on_cancel) && ref($on_cancel) ne 'CODE';
    die "$operation(): unknown option: " . join(', ', sort keys %option)
        if %option;

    return ($on_drain, $on_cancel);
}

sub _validate_options ($class, $kind, %option) {
    _validated_options($kind, %option);
    return;
}

sub _new ($class, $transaction, $kind, %option) {
    my ($on_drain, $on_cancel) = _validated_options($kind, %option);

    my $self = bless {
        transaction  => $transaction,
        kind         => $kind,
        on_drain     => $on_drain,
        on_cancel    => $on_cancel,
        complete     => 0,
        cancelled    => 0,
        flow_blocked => 0,
    }, $class;
    weaken($self->{transaction});
    return $self;
}

sub is_complete  ($self) { !!$self->{complete} }
sub is_cancelled ($self) { !!$self->{cancelled} }

sub _assert_writable ($self, $operation) {
    die "$operation(): streaming body is already complete"
        if $self->{complete};
    die "$operation(): streaming body was cancelled"
        if $self->{cancelled};
    my $transaction = $self->{transaction}
        or die "$operation(): HTTP Transaction is no longer available";
    return $transaction;
}

sub write ($self, $bytes) {
    my $operation = $self->{kind} . '_body->write';
    my $transaction = $self->_assert_writable($operation);
    my $accepted = $transaction->_write_body(
        $self->{kind}, $bytes, 0, $operation,
    );
    $self->{flow_blocked} = 1 if !$accepted;
    return $accepted;
}

sub complete ($self, $bytes = '') {
    my $operation = $self->{kind} . '_body->complete';
    my $transaction = $self->_assert_writable($operation);
    $transaction->_write_body(
        $self->{kind}, $bytes, 1, $operation,
    );
    $self->{complete} = 1;
    $self->{flow_blocked} = 0;
    return $self;
}

sub _block ($self) {
    return if $self->{complete} || $self->{cancelled};
    $self->{flow_blocked} = 1;
    return;
}

sub _drain ($self) {
    return if $self->{complete} || $self->{cancelled};
    return if !$self->{flow_blocked};
    $self->{flow_blocked} = 0;
    my $callback = $self->{on_drain} or return;
    $callback->($self);
    return;
}

sub _cancel ($self) {
    return if $self->{complete} || $self->{cancelled};
    $self->{cancelled} = 1;
    $self->{flow_blocked} = 0;
    my $callback = $self->{on_cancel} or return;
    $callback->($self);
    return;
}

1;

__END__

=head1 NAME

Linux::Event::HTTP::Body::Stream - writable producer for a streaming HTTP body

=head1 DESCRIPTION

Applications obtain this object from a L<Linux::Event::HTTP::Transaction>, for
example C<< $tx->request_body(...) >> while producing a client Request or
C<< $tx->response_body(...) >> while producing a server Response. They do not
construct it directly.

The producer belongs to the Transaction rather than the Request or Response
message. C<write> supplies more body bytes and preserves Linux::Event's
cooperative backpressure return value. False means the bytes were accepted but
the producer should stop until C<on_drain> runs. C<complete> supplies optional
final bytes and announces that no more body bytes will be produced.

C<on_cancel> reports that the HTTP consumer disappeared or the exchange became
terminal before production completed so an upstream producer can stop work.

=cut
