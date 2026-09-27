package Linux::Event::HTTP::Body::Stream;
use v5.36;
use strict;
use warnings;

use Scalar::Util qw(weaken);

our $VERSION = '0.003';

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

    # A protocol controller may discover and then relieve flow pressure while
    # _write_body() is still on the stack. Mark the provisional blocked state
    # first so a reentrant _drain() cannot be lost. A successful write clears
    # it; a false return leaves it set only if no drain already cleared it.
    $self->{flow_blocked} = 1;
    my ($accepted, $ok, $error);
    {
        local $@;
        $ok = eval {
            $accepted = $transaction->_write_body(
                $self->{kind}, $bytes, 0, $operation,
            );
            1;
        };
        $error = $@;
    }
    if (!$ok) {
        $self->{flow_blocked} = 0;
        die $error;
    }

    $self->{flow_blocked} = 0 if $accepted;
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

Linux::Event::HTTP::Body::Stream - writable streaming HTTP body producer

=head1 DESCRIPTION

Applications obtain a Body::Stream from a Transaction. They do not construct it
directly.

Client request body:

    my $body = $operation->request_body;

Server response body:

    my $body = $conn->transaction->response_body(
        on_drain  => sub ($body) { ... },
        on_cancel => sub ($body) { ... },
    );

Write more bytes with:

    my $can_continue = $body->write($bytes);

A false return means the bytes were accepted, but production should pause until
C<on_drain> runs.

Finish with:

    $body->complete;

or provide final bytes:

    $body->complete($final_bytes);

C<on_cancel> runs if the exchange ends before production completes.

The same producer API is used by HTTP/1 and HTTP/2. Protocol-specific framing
and flow control remain below this object.

=head1 SEE ALSO

L<Linux::Event::HTTP::Transaction>, L<Linux::Event::HTTP::Client>,
L<Linux::Event::HTTP::Server>.

=cut
