package Google::gRPC::Client;

use strict;
use warnings;
use Moo;
use Google::gRPC::Channel;
use Google::gRPC::ChannelPool;
use Google::gRPC::Framing;
use Google::gRPC::Deadline;
use Google::gRPC::Status;
use Carp qw(croak);
use Log::Any qw($log);
use Time::HiRes qw(sleep);

our $VERSION = '0.04';

has channel_pool => ( is => 'ro', required => 0 );
has target       => (
    is       => 'ro',
    required => 0,
    lazy     => 1,
    default  => sub {
        my ($self) = @_;
        return $self->channel_pool ? $self->channel_pool->target : undef;
    },
);
has auth_token          => ( is => 'ro', required => 0 );
has proxy               => ( is => 'ro', required => 0 );
has engine_type         => ( is => 'ro', required => 0 );
has timeout             => ( is => 'ro', required => 0 );
has max_retries         => ( is => 'ro', default => sub { 3 } );
has initial_backoff_sec => ( is => 'ro', default => sub { 0.1 } );
has max_backoff_sec     => ( is => 'ro', default => sub { 1.0 } );
has backoff_factor     => ( is => 'ro', default => sub { 2.0 } );
has offline             => ( is => 'ro', default => sub { $ENV{PERL_GRPC_OFFLINE} ? 1 : 0 } );

has channel => ( is => 'ro', lazy => 1, builder => '_build_channel' );

sub BUILD {
    my ($self) = @_;
    if (!$self->target && !$self->channel_pool) {
        croak 'target or channel_pool is required';
    }
}

sub _build_channel {
    my ($self) = @_;
    if ($self->channel_pool) {
        return $self->channel_pool;
    }
    return Google::gRPC::Channel->new(
        target      => $self->target,
        auth_token  => $self->auth_token,
        engine_type => $self->engine_type,
        timeout     => $self->timeout,
    );
}

sub call {
    my ($self, $args) = @_;
    my $service        = $args->{service} or croak 'service is required';
    my $method         = $args->{method} or croak 'method is required';
    my $request        = $args->{request} or croak 'request is required';
    my $response_class = $args->{response_class} or croak 'response_class is required';
    my $timeout_val    = $args->{timeout} // $self->timeout;

    my $max_retries = $args->{max_retries} // $self->max_retries;
    my $backoff     = $args->{initial_backoff_sec} // $self->initial_backoff_sec;
    my $max_backoff = $args->{max_backoff_sec} // $self->max_backoff_sec;
    my $factor      = $args->{backoff_factor} // $self->backoff_factor;

    eval {
        require Net::Curl::Easy;
        Net::Curl::Easy->import(qw(:constants));
    };

    if ($@ || $self->offline) {
        my $stream = $self->channel->create_stream(
            service        => $service,
            method         => $method,
            request        => $request,
            response_class => $response_class,
            type           => 'unary',
            timeout        => $timeout_val,
        );
        my $msg = $stream->recv_message();
        return $msg;
    }

    my $binary_payload = ref($request) && $request->can('serialize') ? $request->serialize() : $request;
    my $framed_payload = Google::gRPC::Framing::pack_frame($binary_payload);

    my $last_exception;
    my $attempt = 0;

    while ($attempt <= $max_retries) {
        $attempt++;

        my $target_host = $self->target;
        my $ch_ref;
        if ($self->channel_pool) {
            $ch_ref = $self->channel_pool->get_channel();
            $target_host = $ch_ref->target;
        }

        my $curl = Net::Curl::Easy->new();
        my $url = 'https://' . $target_host . '/' . $service . '/' . $method;
        $curl->setopt(Net::Curl::Easy::CURLOPT_URL(), $url);
        $curl->setopt(Net::Curl::Easy::CURLOPT_POST(), 1);
        $curl->setopt(Net::Curl::Easy::CURLOPT_POSTFIELDS(), $framed_payload);
        $curl->setopt(Net::Curl::Easy::CURLOPT_POSTFIELDSIZE(), length($framed_payload));

        my @headers = (
            'content-type: application/grpc',
            'te: trailers',
        );
        if ($self->auth_token) {
            push @headers, 'authorization: Bearer ' . $self->auth_token;
        }

        if (defined $timeout_val) {
            my $sec = Google::gRPC::Deadline::parse_timeout($timeout_val);
            if (defined $sec) {
                my $fmt = Google::gRPC::Deadline::format_grpc_timeout($sec);
                push @headers, 'grpc-timeout: ' . $fmt if $fmt;
                my $ms = int($sec * 1000);
                $curl->setopt(Net::Curl::Easy::CURLOPT_TIMEOUT_MS(), $ms > 0 ? $ms : 1);
            }
        }

        $curl->setopt(Net::Curl::Easy::CURLOPT_HTTPHEADER(), \@headers);

        if ($self->proxy) {
            $curl->setopt(Net::Curl::Easy::CURLOPT_PROXY(), $self->proxy);
        }

        my $response_body = '';
        my $headers_received = 0;
        $curl->setopt(Net::Curl::Easy::CURLOPT_WRITEFUNCTION(), sub {
            my ($easy, $data, $usermeta) = @_;
            $response_body .= $data;
            return length($data);
        });

        my %response_headers;
        my $http_code = 0;
        $curl->setopt(Net::Curl::Easy::CURLOPT_HEADERFUNCTION(), sub {
            my ($easy, $header_line, $usermeta) = @_;
            if ($header_line =~ /^HTTP\/[\d\.]+\s+(\d+)/) {
                $http_code = int($1);
            }
            elsif ($header_line =~ /^([^:]+):\s*(.*)\r\n$/) {
                my ($key, $val) = (lc($1), $2);
                $response_headers{$key} = $val;
                $headers_received = 1;
            }
            return length($header_line);
        });

        $log->debugf('gRPC: Dispatching call to %s (attempt %d)', $url, $attempt) if $log;

        my $ret = eval { $curl->perform(); };
        my $curl_err = $@;

        my $trailers = Google::gRPC::Framing::parse_trailers(\%response_headers);
        my $grpc_status = $trailers->{status};

        my $is_transient = 0;
        if ($curl_err || $http_code == 503 || $http_code == 504 || $grpc_status == 14) {
            $is_transient = 1;
        }

        if ($is_transient && $attempt <= $max_retries) {
            $last_exception = $curl_err ? 'gRPC perform failed: ' . $curl_err :
                'gRPC error: status=' . $grpc_status . ', message=' . ($trailers->{message} || 'UNAVAILABLE');

            sleep($backoff);
            $backoff = $backoff * $factor;
            $backoff = $max_backoff if $backoff > $max_backoff;
            next;
        }

        if ($curl_err) {
            croak 'gRPC perform failed: ' . $curl_err;
        }

        if ($grpc_status != 0) {
            my $err_msg = 'gRPC error: status=' . $grpc_status . ', message=' . ($trailers->{message} || 'unknown error');
            if ($trailers->{status_details}) {
                $err_msg .= ', details_code=' . $trailers->{status_details}->code;
            }
            croak $err_msg;
        }

        my @frames = Google::gRPC::Framing::unpack_frame(\$response_body);
        if (!@frames) {
            croak 'Invalid gRPC response: no frames unpacked';
        }

        my $msg_bytes = $frames[0]->{payload};
        my $response = $response_class->parse($msg_bytes);

        if ($self->channel_pool && $ch_ref) {
            my $ip_key = $self->channel_pool->_extract_ip_key($ch_ref->target);
            $self->channel_pool->record_response($ip_key, length($response_body));
        }

        return $response;
    }

    croak $last_exception || 'gRPC call failed after retries';
}

sub stream {
    my ($self, %args) = @_;
    return $self->channel->create_stream(%args);
}


=head1 NAME

Google::gRPC::Client - gRPC Client Interface

=head1 SYNOPSIS

    use Google::gRPC::Client;

=head1 DESCRIPTION

This module provides grpc client interface functionality for the Google gRPC Perl client SDK.

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License 2.0

=cut

1;
