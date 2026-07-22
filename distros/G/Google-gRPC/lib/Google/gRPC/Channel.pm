package Google::gRPC::Channel;

use strict;
use warnings;
use Moo;
use Time::HiRes qw(time);
use Google::gRPC::Engine;
use Google::gRPC::Stream;
use Google::gRPC::Framing;
use Google::gRPC::Deadline;
use Carp qw(croak);

has target                => ( is => 'ro', required => 1 );
has auth_token            => ( is => 'ro', required => 0 );
has engine_type           => ( is => 'ro', required => 0 );
has timeout               => ( is => 'ro', required => 0 );
has keepalive_time_sec    => ( is => 'ro', required => 0 );
has keepalive_timeout_sec => ( is => 'ro', required => 0 );
has engine                => ( is => 'rw' );
has streams               => ( is => 'rw', default => sub { {} } );
has last_activity_time    => ( is => 'rw', default => sub { time() } );

sub BUILD {
    my ($self) = @_;
    my %engine_args;
    if ($self->engine_type) {
        $engine_args{engine} = $self->engine_type;
    }

    my $engine = Google::gRPC::Engine->create(
        %engine_args,
        on_headers => sub {
            my ($sid, $headers) = @_;
            $self->_on_engine_headers($sid, $headers);
        },
        on_data => sub {
            my ($sid, $chunk) = @_;
            $self->_on_engine_data($sid, $chunk);
        },
        on_trailers => sub {
            my ($sid, $trailers) = @_;
            $self->_on_engine_trailers($sid, $trailers);
        },
        on_stream_close => sub {
            my ($sid, $code) = @_;
            $self->_on_engine_close($sid, $code);
        },
    );

    if (ref($engine) && $engine->can('set_callbacks')) {
        $engine->set_callbacks(
            on_headers => sub {
                my ($sid, $headers) = @_;
                $self->_on_engine_headers($sid, $headers);
            },
            on_data => sub {
                my ($sid, $chunk) = @_;
                $self->_on_engine_data($sid, $chunk);
            },
            on_trailers => sub {
                my ($sid, $trailers) = @_;
                $self->_on_engine_trailers($sid, $trailers);
            },
            on_stream_close => sub {
                my ($sid, $code) = @_;
                $self->_on_engine_close($sid, $code);
            },
        );
    }

    $self->engine($engine);
}

sub create_stream {
    my ($self, %opts) = @_;
    my $service        = $opts{service} or croak 'service is required';
    my $method         = $opts{method} or croak 'method is required';
    my $request        = $opts{request};
    my $response_class = $opts{response_class};
    my $type           = $opts{type} || 'unary';
    my $timeout_val    = $opts{timeout} // $self->timeout;

    my $path = '/' . $service . '/' . $method;
    my @headers = (
        ':method'      => 'POST',
        ':path'        => $path,
        ':scheme'      => 'https',
        ':authority'   => $self->target,
        'content-type' => 'application/grpc',
        'te'           => 'trailers',
    );

    if ($self->auth_token) {
        push @headers, 'authorization', 'Bearer ' . $self->auth_token;
    }

    my $deadline_ts;
    if (defined $timeout_val) {
        my $timeout_sec = Google::gRPC::Deadline::parse_timeout($timeout_val);
        if (defined $timeout_sec) {
            $deadline_ts = time() + $timeout_sec;
            my $formatted_hdr = Google::gRPC::Deadline::format_grpc_timeout($timeout_sec);
            push @headers, 'grpc-timeout', $formatted_hdr if $formatted_hdr;
        }
    }

    my $initial_data;
    if (defined $request) {
        my $raw_payload = ref($request) && $request->can('serialize') ? $request->serialize() : $request;
        $initial_data = Google::gRPC::Framing::pack_frame($raw_payload);
    }

    my $end_stream = ($type eq 'unary' || $type eq 'server_stream') ? 1 : 0;

    my $stream_id = $self->engine->submit_request({
        headers    => \@headers,
        data       => $initial_data,
        end_stream => $end_stream,
    });

    my $stream = Google::gRPC::Stream->new(
        stream_id      => $stream_id,
        channel        => $self,
        type           => $type,
        response_class => $response_class,
        on_message     => $opts{on_message},
        on_trailers    => $opts{on_trailers},
        on_close       => $opts{on_close},
        deadline       => $deadline_ts,
    );

    $self->streams->{$stream_id} = $stream;
    $self->last_activity_time(time());
    return $stream;
}

sub send_stream_data {
    my ($self, $stream_id, $data_bytes, $end_stream) = @_;
    if ($self->engine->can('send_data')) {
        $self->engine->send_data($stream_id, $data_bytes, $end_stream);
    }
    $self->last_activity_time(time());
}

sub feed_input {
    my ($self, $bytes) = @_;
    $self->engine->feed_input($bytes);
    $self->last_activity_time(time());
    $self->check_deadlines();
}

sub get_output {
    my ($self) = @_;
    $self->check_deadlines();
    return $self->engine->get_output();
}

sub send_ping {
    my ($self, $cb) = @_;
    if ($self->engine && $self->engine->can('send_ping')) {
        $self->engine->send_ping($cb);
    }
    $self->last_activity_time(time());
}

sub check_keepalive {
    my ($self) = @_;
    return unless defined $self->keepalive_time_sec;
    my $now = time();
    if ($now - $self->last_activity_time >= $self->keepalive_time_sec) {
        $self->send_ping();
    }
}

sub check_deadlines {
    my ($self) = @_;
    for my $sid (keys %{$self->streams}) {
        my $stream = $self->streams->{$sid};
        if ($stream) {
            $stream->check_deadline();
        }
    }
}

sub _on_engine_headers {
    my ($self, $sid, $headers) = @_;
    my $stream = $self->streams->{$sid};
    return unless $stream;
    $stream->headers_received(1);
    $self->last_activity_time(time());
}

sub _on_engine_data {
    my ($self, $sid, $chunk) = @_;
    my $stream = $self->streams->{$sid};
    return unless $stream;
    $stream->push_incoming_data($chunk);
    $self->last_activity_time(time());
}

sub _on_engine_trailers {
    my ($self, $sid, $trailers) = @_;
    my $stream = $self->streams->{$sid};
    return unless $stream;
    $stream->handle_trailers($trailers);
    $self->last_activity_time(time());
}

sub _on_engine_close {
    my ($self, $sid, $code) = @_;
    my $stream = $self->streams->{$sid};
    return unless $stream;
    $stream->handle_close($code);
    $self->last_activity_time(time());
}


=head1 NAME

Google::gRPC::Channel - gRPC Channel Abstraction

=head1 SYNOPSIS

    use Google::gRPC::Channel;

=head1 DESCRIPTION

This module provides grpc channel abstraction functionality for the Google gRPC Perl client SDK.

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License 2.0

=cut

1;
