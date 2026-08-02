package Fetch;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Fetch', $VERSION);

require Fetch::Future;
require Fetch::Loop;
require Fetch::Loop::Standalone;
require Fetch::Response;
require Fetch::Headers;
require Fetch::CookieJar;
require Fetch::WebSocket;

1;

__END__

=head1 NAME

Fetch - HTTP/2 Future-based user agent

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Fetch;

    # works out of the box - no event loop to set up
    my $res = Fetch->new->get('https://example.com')->get;
    print $res->content if $res->is_success;

    # every call returns a Fetch::Future; ->get awaits it
    my $ua  = Fetch->new(timeout => 10);
    my $f   = $ua->post('https://api/things',
                        headers => { 'Content-Type' => 'application/json' },
                        body    => '{"name":"x"}');
    my $res = $f->get;

    # many requests concurrently on one loop
    my @futs = map { $ua->get($_) } @urls;
    Fetch::Future->needs_all(@futs)->get;
    my @bodies = map { $_->get->content } @futs;

    # a live WebSocket
    my $ws = $ua->websocket('wss://host/socket')->get;
    $ws->send('hello');
    my $reply = $ws->next_message->get;

=head1 DESCRIPTION

Fetch is an HTTP user agent whose socket, TLS, HTTP/2 framing and HTTP/1.1
parsing hot path lives in vendored C, and whose asynchronous results are
L<Fetch::Future> objects that compose with the Hyperman event loop and other
CPAN loops (IO::Async, AnyEvent) - or with nothing at all, since Fetch ships
its own event loop (L<Fetch::Loop::Standalone>) and uses it automatically.

HTTP/1.1 and HTTP/2 (ALPN-negotiated over TLS), over cleartext and TLS, with
keep-alive connection pooling, redirect following, per-request timeouts,
streaming response bodies, a cookie jar, JSON request/response helpers, and
native WebSockets. Every request method returns a
L<Fetch::Future>; C<< ->get >> on one awaits it, pumping whichever event loop
is active (its own if none), so the same code serves both a simple synchronous
call and thousands of requests multiplexed on one loop.

=head1 CONSTRUCTOR

=head2 new(%args)

    my $ua = Fetch->new(
        timeout    => 10,
        tls_verify => 1,
        headers    => { 'Accept' => 'application/json' },
        cookie_jar => 1,
    );

Create a user agent. All arguments are optional:

=over 4

=item C<loop>

The event loop to run on. Omit it and Fetch uses its own
L<Fetch::Loop::Standalone> (so C<< ->get >> just works with no framework). Pass
a raw L<IO::Async::Loop> or L<Hyperman::Loop> and it is wrapped automatically;
pass the string C<'AnyEvent'> to drive AnyEvent; or pass a ready-made
L<Fetch::Loop> adapter. See L</"EVENT LOOPS">.

=item C<headers>

Default headers sent on every request, as a hashref, an arrayref of
C<< name => value >> pairs (duplicates preserved), or a L<Fetch::Headers>.
Per-request C<headers> are merged on top (see L</"REQUEST OPTIONS">).

=item C<agent>

The C<User-Agent> string. Defaults to C<"Fetch/$VERSION">.

=item C<tls_verify>

Whether to verify the peer certificate and hostname for C<https>. Default true.
Overridable per request.

=item C<timeout>

Default per-request deadline in seconds (fractional allowed). C<0> (the
default) means no timeout. Overridable per request.

=item C<max_redirects>

How many redirects to follow. Default C<5>; C<0> disables following.
Overridable per request.

=item C<keep_alive>

Reuse connections via a keep-alive pool (default true). Set false to close
every connection after one request.

=item C<pool_size>

Maximum idle connections the keep-alive pool parks (default C<32>).

=item C<cookie_jar>

A L<Fetch::CookieJar> to store and send cookies (applied across redirects), or
a true scalar to create a fresh one. Default: no jar.

=item C<simple_response>

Resolve requests to a plain unblessed hashref C<< { status => ..., headers =>
[k, v, ...], content => ... } >> instead of a blessed L<Fetch::Response>. Read
fields directly (C<< $res->{status} >>, C<< $res->{content} >>) rather than via
methods. This skips the response object's method dispatch on the hot path; the
saving is small (a couple of percent) and only shows when you actually read the
response, so reach for it when you are consuming millions of responses and want
the leanest possible per-response cost. Default false.

=back

=head1 REQUEST METHODS

Each returns a L<Fetch::Future> that resolves to a L<Fetch::Response> (or fails
with an error string). They never block; call C<< ->get >> on the future to
await the result.

=head2 get / head / delete

    my $f = $ua->get($url, %opt);

=head2 post / put

    my $f = $ua->post($url, body => $bytes, %opt);

=head2 request($method, $url, %opt)

    my $f = $ua->request('PATCH', $url, body => $bytes, %opt);

The general form the verb helpers dispatch to; use it for any method.

=head1 REQUEST OPTIONS

Passed as a trailing C<< key => value >> list to any request method:

=over 4

=item C<headers>

Extra headers for this request - a hashref, an arrayref of pairs (keeping
duplicate names, e.g. multiple C<X-*> values), or a L<Fetch::Headers>. Each
named field overrides the agent default of the same name.

=item C<body>

The request body (bytes). Content-Length is added automatically unless you
set it yourself.

=item C<json>

A Perl data structure to send as a JSON body: it is encoded and
C<Content-Type: application/json> is set (unless you gave your own). Takes
precedence over C<body>. Pair it with L<Fetch::Response/json> to decode the
reply. Encoding uses L<Cpanel::JSON::XS> when installed, else core L<JSON::PP>.

    my $res  = $ua->post($url, json => { name => 'x', ok => \1 })->get;
    my $data = $res->json;

=item C<timeout>

Override the agent timeout for this request (seconds; C<0> disables it).

=item C<tls_verify>

Override certificate/hostname verification for this C<https> request.

=item C<max_redirects>

Override how many redirects this request follows.

=item C<on_body>

A coderef called with each body chunk as it arrives, instead of buffering.
Suits large downloads and server-sent events: the buffer is compacted so an
endless stream does not grow memory, and the resolved response body is empty.

    $ua->get($url, on_body => sub { my ($chunk) = @_; print $chunk })->get;

=back

=head1 WEBSOCKETS

=head2 websocket($url, %opt)

    my $ws = $ua->websocket('ws://host/echo')->get;   # or wss://

Open a WebSocket (RFC 6455). Returns a L<Fetch::Future> that resolves, after
the C<101> handshake, to a L<Fetch::WebSocket> for sending and receiving
messages. Accepts C<ws://>/C<wss://> (and C<http>/C<https>); C<tls_verify> and
C<timeout> options apply to the handshake.

=head1 ACCESSORS

=head2 loop

The event-loop adapter this agent runs on.

=head2 cookie_jar

The L<Fetch::CookieJar> in use, or undef.

=head1 THE RESULT

Awaiting a request future yields a L<Fetch::Response> with C<status>,
C<headers> (a L<Fetch::Headers>), C<content>, C<header($name)>, C<is_success>
and C<is_redirect>. A failed request (connection error, timeout, bad TLS, a
rejected WebSocket upgrade) fails the future with a message; C<< ->get >>
rethrows it, or inspect C<< $f->failure >> / C<< $f->is_failed >>.

=head1 EVENT LOOPS

C<< $future->get >> awaits by pumping the active loop, so a bare synchronous
call needs no setup. Hand Fetch a loop to cooperate with an existing async
program - requests then fly concurrently on that one loop without blocking it:

    use IO::Async::Loop;
    my $loop = IO::Async::Loop->new;
    my $ua   = Fetch->new(loop => $loop);       # shares this loop
    my $f    = $ua->get('https://example.com/');
    $loop->loop_once until $f->is_ready;
    my $res  = $f->get;

Supported loops: the built-in L<Fetch::Loop::Standalone>, plus
L<Fetch::Loop::IOAsync>, L<Fetch::Loop::AnyEvent> and L<Fetch::Loop::Hyperman>.

=head1 SEE ALSO

L<Fetch::Response>, L<Fetch::Headers>, L<Fetch::CookieJar>, L<Fetch::WebSocket>,
L<Fetch::Future>, L<Fetch::Loop> and the loop adapters
L<Fetch::Loop::Standalone>, L<Fetch::Loop::IOAsync>, L<Fetch::Loop::AnyEvent>,
L<Fetch::Loop::Hyperman>.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
