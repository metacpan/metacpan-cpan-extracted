package Linux::Event::HTTP;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.003';

1;

__END__

=head1 NAME

Linux::Event::HTTP - HTTP/1.x and HTTP/2 for Linux::Event

=head1 VERSION

Version 0.003

=head1 SYNOPSIS

Server:

    use Linux::Event::Loop;
    use Linux::Event::HTTP::Server;

    my $loop = Linux::Event::Loop->new;

    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        port => 8080,
        on_request => sub ($conn, $req, $res) {
            $res->body("hello\n");
        },
    );

    $loop->run;

HTTP/2 over HTTPS uses the same Server API:

    my $server = Linux::Event::HTTP::Server->new(
        loop  => $loop,
        port  => 8443,
        http2 => 1,
        tls => {
            cert_file => '/path/server-cert.pem',
            key_file  => '/path/server-key.pem',
        },
        on_request => sub ($conn, $req, $res) {
            $res->body("hello\n");
        },
    );

Client:

    use Linux::Event::HTTP::Client;

    my $client = Linux::Event::HTTP::Client->new(
        loop  => $loop,
        http2 => 1,
    );

    my $operation = $client->get(
        'https://example.com/',
        on_body => sub ($tx, $res, $bytes) {
            process_bytes($bytes);
        },
        on_complete => sub ($tx) {
            say $tx->response->status;
        },
    );

=head1 DESCRIPTION

Linux::Event::HTTP is the HTTP communications layer for L<Linux::Event>. It
provides asynchronous HTTP servers and clients while deliberately remaining a
protocol layer rather than a web framework.

HTTP/1.x and HTTP/2 share the same public message and exchange model:

=over 4

=item * L<Linux::Event::HTTP::Request>

One HTTP request message.

=item * L<Linux::Event::HTTP::Response>

One HTTP response message.

=item * L<Linux::Event::HTTP::Transaction>

Exactly one Request/Response exchange.

=item * L<Linux::Event::HTTP::Client::Operation>

One high-level client action. Redirects and authentication retries may create
additional Transactions inside the same Operation.

=item * L<Linux::Event::HTTP::Server> and L<Linux::Event::HTTP::Client>

The ordinary high-level server and client entry points.

=back

Linux::Event owns sockets, TLS, readiness, transport buffering, and transport
backpressure. Linux::Event::HTTP owns HTTP parsing, framing, persistence,
message lifecycle, client policy, and HTTP protocol execution.

=head1 HTTP VERSIONS

HTTP/1 support is built in.

HTTP/2 is optional and uses L<Net::HTTP2::nghttp2> 0.011 or newer as the
libnghttp2 binding. Enable it on the high-level Server or Client with:

    http2 => 1

The production HTTP/2 path is HTTPS negotiated with ALPN. C<h2> is preferred
and C<http/1.1> is the fallback, so applications keep the same high-level API
regardless of which version is selected.

The optional HTTP/2 dependency is not required for HTTP/1-only installations.

=head1 BODY MODEL

Incoming bodies are streaming-first. They are not accumulated into unbounded
scalars automatically.

Outgoing complete bodies may be set directly on Request or Response objects.
Outgoing incremental bodies use L<Linux::Event::HTTP::Body::Stream> producers
owned by the Transaction.

Client responses may be buffered only when an explicit bounded C<buffer_body>
limit is supplied.

=head1 HTTP/1 HANDOFF

HTTP/1.1 Upgrade and CONNECT can transfer the same live Linux::Event stream to
another protocol class. The handoff is owned by Transaction and preserves bytes
already read beyond the HTTP message boundary.

=head1 DOCUMENTATION

Start with F<README.md> for ordinary Server and Client usage.

The main public APIs are documented in:

=over 4

=item * L<Linux::Event::HTTP::Server>

=item * L<Linux::Event::HTTP::Client>

=item * L<Linux::Event::HTTP::Request>

=item * L<Linux::Event::HTTP::Response>

=item * L<Linux::Event::HTTP::Transaction>

=item * L<Linux::Event::HTTP::Client::Operation>

=back

Maintainer and design documentation is under F<docs/>.

=head1 THIRD-PARTY CODE

The distribution includes picohttpparser by Kazuho Oku and contributors for the
native HTTP/1 header parsing path. Its source and license are under
F<vendor/picohttpparser/>.

The high-level Client uses L<URI>, L<HTTP::CookieJar>, and
L<Uniform::HTTP::Auth> for their respective policy areas.

HTTP/2 uses the optional L<Net::HTTP2::nghttp2> binding.

=head1 SECURITY

See F<SECURITY.md> for vulnerability reporting instructions.

=head1 AUTHOR

Joshua S. Day E<lt>hax@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) 2026 Joshua S. Day.

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl 5 itself.

The vendored picohttpparser source retains its upstream license in
F<vendor/picohttpparser/LICENSE>.

=cut
