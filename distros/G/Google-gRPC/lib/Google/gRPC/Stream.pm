package Google::gRPC::Stream;

use strict;
use warnings;
use Moo;
use Time::HiRes qw(time);
use Google::gRPC::Framing;
use Carp qw(croak);

has stream_id      => ( is => 'ro', required => 1 );
has channel        => ( is => 'ro', required => 1 );
has type           => ( is => 'ro', default => sub { 'unary' } );
has response_class => ( is => 'ro', required => 0 );
has on_message     => ( is => 'rw' );
has on_trailers    => ( is => 'rw' );
has on_close       => ( is => 'rw' );
has pool           => ( is => 'rw' );
has ip_key         => ( is => 'rw' );
has deadline       => ( is => 'rw' );

has state            => ( is => 'rw', default => sub { 'open' } );
has read_buffer      => ( is => 'rw', default => sub { '' } );
has response_queue   => ( is => 'rw', default => sub { [] } );
has status           => ( is => 'rw', default => sub { 0 } );
has status_message   => ( is => 'rw', default => sub { '' } );
has status_details   => ( is => 'rw' );
has headers_received => ( is => 'rw', default => sub { 0 } );

sub write_message {
    my ($self, $msg, $end_stream) = @_;
    $self->check_deadline();
    return if $self->state eq 'closed';

    my $binary_payload;
    if (ref($msg) && $msg->can('serialize')) {
        $binary_payload = $msg->serialize();
    }
    elsif (defined $msg) {
        $binary_payload = $msg;
    }
    else {
        $binary_payload = '';
    }

    my $framed = Google::gRPC::Framing::pack_frame($binary_payload);
    if ($self->pool && $self->ip_key) {
        $self->pool->record_request($self->ip_key, length($framed));
    }
    $self->channel->send_stream_data($self->stream_id, $framed, $end_stream);

    if ($end_stream) {
        if ($self->state eq 'half_closed_remote') {
            $self->state('closed');
        }
        else {
            $self->state('half_closed_local');
        }
    }
}

sub close_write {
    my ($self) = @_;
    $self->write_message(undef, 1);
}

sub push_incoming_data {
    my ($self, $chunk) = @_;
    $self->check_deadline();
    return if $self->state eq 'closed';
    return unless defined $chunk && length($chunk);

    my $buf = $self->read_buffer . $chunk;
    my @frames = Google::gRPC::Framing::unpack_frame(\$buf);
    $self->read_buffer($buf);

    for my $frame (@frames) {
        my $payload = $frame->{payload};
        my $parsed_msg = $payload;

        if ($self->response_class && $self->response_class->can('parse')) {
            $parsed_msg = $self->response_class->parse($payload);
        }

        push @{$self->response_queue}, $parsed_msg;

        if (my $cb = $self->on_message) {
            $cb->($self, $parsed_msg);
        }
    }
}

sub recv_message {
    my ($self) = @_;
    $self->check_deadline();
    return shift @{$self->response_queue};
}

sub handle_trailers {
    my ($self, $trailers) = @_;
    return if $self->state eq 'closed';

    my $info = Google::gRPC::Framing::parse_trailers($trailers);
    $self->status($info->{status});
    $self->status_message($info->{message});
    if ($info->{status_details}) {
        $self->status_details($info->{status_details});
    }

    if (my $cb = $self->on_trailers) {
        $cb->($self, $info);
    }
}

sub handle_close {
    my ($self, $code) = @_;
    return if $self->state eq 'closed';
    $self->state('closed');
    if (my $cb = $self->on_close) {
        $cb->($self, $self->status, $self->status_message);
    }
}

sub check_deadline {
    my ($self) = @_;
    return unless defined $self->deadline;
    return if $self->state eq 'closed';

    if (time() > $self->deadline) {
        $self->abort_stream(4, 'Deadline Exceeded');
    }
}

sub abort_stream {
    my ($self, $status_code, $status_msg) = @_;
    $status_code //= 4;
    $status_msg //= 'Deadline Exceeded';

    $self->status($status_code);
    $self->status_message($status_msg);

    my $info = {
        status  => $status_code,
        message => $status_msg,
    };

    if (my $cb = $self->on_trailers) {
        $cb->($self, $info);
    }
    $self->handle_close($status_code);
}


=head1 NAME

Google::gRPC::Stream - gRPC Stream Interface

=head1 SYNOPSIS

    use Google::gRPC::Stream;

=head1 DESCRIPTION

This module provides grpc stream interface functionality for the Google gRPC Perl client SDK.

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License 2.0

=cut

1;
