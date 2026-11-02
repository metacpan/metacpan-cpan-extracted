package Linux::Event::HTTP;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.005';

1;

__END__

=head1 NAME

Linux::Event::HTTP - HTTP servers and clients for Linux::Event

=head1 SYNOPSIS

Start an HTTP server:

    use v5.36;
    use Linux::Event::Loop;
    use Linux::Event::HTTP::Server;

    my $loop = Linux::Event::Loop->new;
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        port => 8080,
        on_request => sub ($tx, $req) {
            $tx->respond(status => 200, body => "Hello\n");
        },
    );

    $loop->run;

Or make a request with L<Linux::Event::HTTP::Client>:

    use v5.36;
    use Linux::Event::Loop;
    use Linux::Event::HTTP::Client;

    my $loop = Linux::Event::Loop->new;
    my $client = Linux::Event::HTTP::Client->new(loop => $loop);

    $client->get(
        'https://example.com/',
        timeout => 15,
        on_response => sub ($tx, $res) {
            say $res->status;
            say $res->body;
        },
        on_error => sub ($object, $error, @details) {
            warn "$error\n";
        },
        on_finish => sub { $loop->stop },
    );

    $loop->run;

=head1 DESCRIPTION

Linux::Event::HTTP lets Linux::Event programs make HTTP requests or
serve HTTP responses without managing socket reads or parsing HTTP.

HTTP/1.1 is enabled by default. HTTP/2 over TLS and HTTP/3 over QUIC
are optional. A Client can make multiple requests and reuse connections.
A Server accepts incoming connections and calls your code for each request.

Use L<Linux::Event::HTTP::Client> to make requests or
L<Linux::Event::HTTP::Server> to receive them.

=head1 CALLBACKS IN BRIEF

A server's C<on_request> runs after the entire incoming request has
arrived. The callback receives a transaction C<$tx> to respond through
and a request C<$req> to inspect.

A client's C<on_response> receives a complete response by default.
If you supply C<on_data>, C<on_response> instead runs at response
headers, and C<on_data> receives each body chunk. C<on_error> handles
failures; C<on_finish> runs when the operation ends.

=head1 FURTHER READING

The distribution's README and C<docs/GETTING-STARTED.md> contain
complete introductory examples, including POST, request routing,
streaming, HTTPS, and shutdown.

Linux::Event owns sockets, TLS, and timers. The protocol engines are
provided by L<Unblock::HTTP>, and request/response objects by
L<Uniform::HTTP>. You do not need to use their APIs directly for
ordinary HTTP applications.

Version 0.004 replaced the previous public API. See the release notes
for migration information and current protocol limitations.

=cut
