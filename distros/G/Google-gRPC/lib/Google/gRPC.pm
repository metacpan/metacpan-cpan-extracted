package Google::gRPC;

use strict;
use warnings;

our $VERSION = '0.09';

1;

__END__

=encoding UTF-8

=head1 NAME

Google::gRPC - High-performance gRPC client library for Perl over HTTP/2

=head1 VERSION

Version 0.09

=head1 SYNOPSIS

    use Google::Auth;
    use Google::gRPC::Client;
    use Google::gRPC::ChannelPool;

    my $auth  = Google::Auth->default();
    my $token = $auth->get_token();

    # 1. Basic unary gRPC client
    my $client = Google::gRPC::Client->new(
        target      => 'spanner.googleapis.com:443',
        auth_token  => $token,
        timeout     => 30,
        max_retries => 3,
    );

    my $response = $client->call({
        service        => 'google.spanner.v1.Spanner',
        method         => 'CreateSession',
        request        => $request_msg,
        response_class => 'Google::Cloud::Spanner::V1::Session',
    });

    # 2. Pooled multi-channel client for high-throughput services
    my $pool = Google::gRPC::ChannelPool->new(
        target   => 'spanner.googleapis.com:443',
        channels => 4,
    );
    my $pooled_client = Google::gRPC::Client->new(
        channel_pool => $pool,
        auth_token   => $token,
    );

=head1 DESCRIPTION

C<Google::gRPC> is a Perl gRPC client library designed for Google Cloud APIs
and general-purpose HTTP/2 gRPC services (comparable to Go's
C<google.golang.org/grpc>, Python's C<grpcio>, Ruby's C<grpc>, Java's
C<grpc-java>, and C++'s C<grpc++>).

It provides:

=over 4

=item * B<Unary & Streaming RPCs:> Full support for unary, server-streaming, client-streaming, and bidirectional-streaming RPCs via L<Google::gRPC::Client> and L<Google::gRPC::Stream>.

=item * B<HTTP/2 Engines:> Native C/XS C<libnghttp2> engine (L<Google::gRPC::Engine::NGHTTP2>) with automatic fallback to Pure-Perl L<Protocol::HTTP2> (L<Google::gRPC::Engine::PP>), plus L<Net::Curl::Easy> for live unary calls.

=item * B<Deadlines, Retries & Keepalive:> Automatic C<grpc-timeout> deadline formatting, exponential backoff retries on transient HTTP/gRPC errors (429/502/503/504 and C<UNAVAILABLE>), and HTTP/2 keepalive pings.

=item * B<Channel Pooling:> Multi-subchannel load balancing and response-byte tracking via L<Google::gRPC::ChannelPool>.

=item * B<Protobuf Integration:> Seamless serialization/deserialization with L<Protobuf> message classes and standard gRPC length-prefixed framing (L<Google::gRPC::Framing>).

=back

=head1 SUBMODULES

=over 4

=item * L<Google::gRPC::Client> - High-level unary (C<call>) and streaming (C<stream>) gRPC client with retries, auth headers, and deadlines.

=item * L<Google::gRPC::Channel> - Single HTTP/2 channel managing multiplexed gRPC streams and keepalive state.

=item * L<Google::gRPC::ChannelPool> - Pool of subchannels for connection reuse and load distribution.

=item * L<Google::gRPC::Stream> - Stream handle for sending and receiving framed gRPC messages and trailers.

=item * L<Google::gRPC::Deadline> - Parsing and formatting for C<grpc-timeout> headers.

=item * L<Google::gRPC::Status> - Standard gRPC status codes and rich C<grpc-status-details-bin> error decoding.

=item * L<Google::gRPC::Framing> - 5-byte gRPC length-prefixed frame packing/unpacking and trailer parsing.

=item * L<Google::gRPC::Engine> - Engine factory selecting C<NGHTTP2> (XS) or C<PP> (Pure-Perl).

=back

=head1 ENVIRONMENT VARIABLES

=over 4

=item * C<GOOGLE_CLOUD_QUOTA_PROJECT> - Sent as the C<x-goog-user-project> metadata header on RPC calls.

=item * C<PERL_GRPC_OFFLINE> - Enables offline/in-memory channel execution for unit testing.

=back

=head1 SEE ALSO

L<Google::Auth>, L<Google::Api::Common>, L<Protobuf>,
L<Module::Starter::Protobuf>, L<https://grpc.io/docs/>

=head1 SUPPORT AND BUG TRACKING

Report bugs or feature requests via GitHub:

L<https://github.com/GoogleCloudPlatform/google-auth-library-perl/issues>

or CPAN RT:

L<https://rt.cpan.org/Dist/Display.html?Name=Google-gRPC>

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License, Version 2.0

=cut
