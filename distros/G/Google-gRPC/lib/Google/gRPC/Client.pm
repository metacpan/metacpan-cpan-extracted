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

our $VERSION = '0.10';

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

    if ($self->offline) {
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

    my $curl_err;
    {
        local $@;
        eval {
            require Net::Curl::Easy;
            Net::Curl::Easy->import(qw(:constants));
        };
        $curl_err = $@;
    }
    if ($curl_err) {
        croak 'Failed to load Net::Curl::Easy for live gRPC transport (set offline => 1 for offline mode): ' . $curl_err;
    }

    my $binary_payload = ref($request) && $request->can('serialize') ? $request->serialize() : $request;
    my $framed_payload = Google::gRPC::Framing::pack_frame($binary_payload);

    my $last_exception;
    my $attempt = 0;

    while ($attempt <= $max_retries) {
        $attempt++;

        my $target_host = $self->target;
        my $ch_ref;
        my @resolve_entries;
        if ($self->channel_pool) {
            $ch_ref = $self->channel_pool->get_channel();
            $target_host = $self->channel_pool->target;

            my ($logical_host, $logical_port);
            if ($target_host =~ /^\[([a-fA-F0-9:]+)\](?::(\d+))?$/) {
                $logical_host = $1;
                $logical_port = $2 || '443';
            } elsif ($target_host =~ /^([^:]+):(\d+)$/) {
                $logical_host = $1;
                $logical_port = $2;
            } else {
                $logical_host = $target_host;
                $logical_port = '443';
            }

            my $sub_target = $ch_ref->target;
            my $pinned_ip;
            if ($sub_target =~ /^\[([a-fA-F0-9:]+)\](?::\d+)?$/) {
                $pinned_ip = '[' . $1 . ']';
            } elsif ($sub_target =~ /^([^:]+):\d+$/) {
                $pinned_ip = $1;
            } else {
                $pinned_ip = $sub_target;
            }

            if (defined $pinned_ip && $pinned_ip ne $logical_host && $pinned_ip ne ('[' . $logical_host . ']')) {
                push @resolve_entries, "${logical_host}:${logical_port}:${pinned_ip}";
            }
        }

        my $curl = Net::Curl::Easy->new();
        if (@resolve_entries && Net::Curl::Easy->can('CURLOPT_RESOLVE')) {
            $curl->setopt(Net::Curl::Easy::CURLOPT_RESOLVE(), \@resolve_entries);
        }
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

        if ($ENV{GOOGLE_CLOUD_QUOTA_PROJECT}) {
            push @headers, 'x-goog-user-project: ' . $ENV{GOOGLE_CLOUD_QUOTA_PROJECT};
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

        my $trailers    = Google::gRPC::Framing::parse_trailers(\%response_headers);
        my $has_status  = $trailers->{has_status};
        my $grpc_status = $has_status ? $trailers->{status} : undef;

        if (!defined $grpc_status && $http_code != 200) {
            my %http_to_grpc = (
                400 => 13,    # INTERNAL
                401 => 16,    # UNAUTHENTICATED
                403 => 7,     # PERMISSION_DENIED
                404 => 12,    # UNIMPLEMENTED
                429 => 14,    # UNAVAILABLE
                502 => 14,    # UNAVAILABLE
                503 => 14,    # UNAVAILABLE
                504 => 14,    # UNAVAILABLE
            );
            $grpc_status = $http_to_grpc{$http_code} // 2;    # UNKNOWN
        }

        my $is_transient = 0;
        if ( $curl_err
            || $http_code == 429
            || $http_code == 502
            || $http_code == 503
            || $http_code == 504
            || (defined $grpc_status && $grpc_status == 14) )
        {
            $is_transient = 1;
        }

        if ($is_transient && $attempt <= $max_retries) {
            $last_exception = $curl_err
                ? 'gRPC perform failed: ' . $curl_err
                : 'gRPC error: status=' . ($grpc_status // 'missing') . ', message=' . ($trailers->{message} || 'UNAVAILABLE');

            sleep($backoff);
            $backoff = $backoff * $factor;
            $backoff = $max_backoff if $backoff > $max_backoff;
            next;
        }

        if ($curl_err) {
            croak 'gRPC perform failed: ' . $curl_err;
        }

        if ($http_code != 200 && !defined $grpc_status) {
            croak 'gRPC HTTP error: http_status=' . $http_code;
        }

        if (!defined $grpc_status) {
            croak 'Invalid gRPC response: missing grpc-status trailer (http_status=' . $http_code . ')';
        }

        if ($grpc_status != 0) {
            my $err_msg = 'gRPC error: status=' . $grpc_status . ', message=' . ($trailers->{message} || 'HTTP ' . $http_code);
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

Google::gRPC::Client - Unary and streaming gRPC client interface over HTTP/2

=head1 SYNOPSIS

    use Google::Auth;
    use Google::gRPC::Client;
    use Google::Cloud::Spanner::V1::Spanner; # or any Protobuf message classes

    my $auth  = Google::Auth->default();
    my $token = $auth->get_token();

    my $client = Google::gRPC::Client->new(
        target      => 'spanner.googleapis.com:443',
        auth_token  => $token,
        timeout     => 30,    # seconds (or gRPC duration string such as '30S')
        max_retries => 3,
    );

    # Unary RPC call
    my $response = $client->call({
        service        => 'google.spanner.v1.Spanner',
        method         => 'CreateSession',
        request        => $request_msg,
        response_class => 'Google::Cloud::Spanner::V1::Session',
    });

    # Streaming RPC call
    my $stream = $client->stream(
        service        => 'google.spanner.v1.Spanner',
        method         => 'ExecuteStreamingSql',
        request        => $sql_request_msg,
        response_class => 'Google::Cloud::Spanner::V1::PartialResultSet',
        type           => 'server_streaming',
    );
    while (my $chunk = $stream->recv_message()) {
        ...
    }

=head1 DESCRIPTION

C<Google::gRPC::Client> implements the high-level gRPC client interface for
Google Cloud Perl SDKs. It handles gRPC length-prefixed framing, HTTP/2
transport via L<Net::Curl::Easy> (or L<Google::gRPC::Channel> in offline mode),
Bearer token and quota-project header injection, deadline propagation
(C<grpc-timeout>), exponential backoff retries on transient HTTP/gRPC errors,
and optional connection pooling via L<Google::gRPC::ChannelPool>.

=head1 CONSTRUCTOR / ATTRIBUTES

Pass these options to C<< Google::gRPC::Client->new(...) >>. Either C<target>
or C<channel_pool> is required.

=over 4

=item * B<target>

The C<host:port> endpoint to connect to (e.g., C<'spanner.googleapis.com:443'>).
Optional if C<channel_pool> is provided (defaults to the pool's target).

=item * B<channel_pool>

An optional L<Google::gRPC::ChannelPool> instance for load-balancing and
pinning resolved IPs across multiple subchannels.

=item * B<auth_token>

Optional OAuth 2.0 Bearer access token sent in the C<authorization> header.

=item * B<proxy>

Optional HTTP/HTTPS proxy URL passed to C<CURLOPT_PROXY>.

=item * B<engine_type>

Optional HTTP/2 engine selection passed to L<Google::gRPC::Channel> (e.g.,
C<'nghttp2'> or C<'pp'>).

=item * B<timeout>

Optional default per-RPC deadline in seconds or gRPC timeout format (parsed via
L<Google::gRPC::Deadline>).

=item * B<max_retries>

Maximum number of retry attempts on transient transport errors (HTTP 429, 502,
503, 504 or gRPC status C<UNAVAILABLE> / 14). Defaults to C<3>.

=item * B<initial_backoff_sec>

Initial retry backoff delay in seconds. Defaults to C<0.1>.

=item * B<max_backoff_sec>

Maximum retry backoff delay in seconds. Defaults to C<1.0>.

=item * B<backoff_factor>

Multiplier applied to the backoff delay after each retry. Defaults to C<2.0>.

=item * B<offline>

Boolean flag enabling offline/in-memory channel execution via
L<Google::gRPC::Channel> without requiring L<Net::Curl::Easy>. Defaults to true
when C<$ENV{PERL_GRPC_OFFLINE}> is set.

=item * B<channel>

Lazy-built L<Google::gRPC::Channel> (or the configured C<channel_pool>).

=back

=head1 METHODS

=head2 call

    my $response = $client->call({
        service             => 'google.spanner.v1.Spanner',
        method              => 'CreateSession',
        request             => $request_obj_or_bytes,
        response_class      => 'Google::Cloud::Spanner::V1::Session',
        timeout             => 15,   # optional override
        max_retries         => 3,    # optional override
        initial_backoff_sec => 0.1,  # optional override
        max_backoff_sec     => 1.0,  # optional override
        backoff_factor      => 2.0,  # optional override
    });

Executes a unary gRPC call. C<request> may be a Protobuf message object
implementing C<serialize()> or raw serialized protobuf bytes. Returns an
instance of C<response_class> decoded via C<< $response_class->parse($bytes) >>.
Croaks on transport errors, missing C<grpc-status> trailers, or non-zero gRPC
status codes after exhausting retries.

=head2 stream

    my $stream = $client->stream(
        service        => 'google.spanner.v1.Spanner',
        method         => 'ExecuteStreamingSql',
        request        => $request_obj,
        response_class => 'Google::Cloud::Spanner::V1::PartialResultSet',
        type           => 'server_streaming',
    );

Creates and returns a L<Google::gRPC::Stream> via the underlying channel.

=head1 ENVIRONMENT VARIABLES

=over 4

=item * C<GOOGLE_CLOUD_QUOTA_PROJECT>

When set, sent as the C<x-goog-user-project> gRPC metadata header on every call.

=item * C<PERL_GRPC_OFFLINE>

When set to a true value, defaults C<offline> to C<1>.

=back

=head1 SEE ALSO

L<Google::gRPC>, L<Google::gRPC::Channel>, L<Google::gRPC::ChannelPool>,
L<Google::gRPC::Stream>, L<Google::gRPC::Deadline>, L<Google::gRPC::Status>,
L<Google::Auth>

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License 2.0

=cut

1;
