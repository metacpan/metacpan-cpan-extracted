package EV::YACurl;

use 5.010000;
use strict;
use warnings;

use EV ();

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('EV::YACurl', $VERSION);

require constant;
my %constants = %{ _get_known_constants() };
constant->import(\%constants);

use Exporter 'import';
our @EXPORT_OK = keys %constants;
our %EXPORT_TAGS = (constants => [keys %constants]);

# Called from XS so that a $SIG{__WARN__} handler which dies is caught at the
# eval around this call instead of unwinding through libcurl.
sub _warn { warn $_[0] }

# A client wraps C state that belongs to one interpreter. Cloning the wrapper
# into a new thread would hand two interpreters the same pointer to free.
sub CLONE_SKIP { 1 }
sub EV::YACurl::Response::CLONE_SKIP { 1 }

1;

=head1 NAME

EV::YACurl - Yet Another curl binding for EV

=head1 SYNOPSIS

    use EV;
    use EV::YACurl ':constants';

    my $client = EV::YACurl->new({});
    my ($done, $failed, $body) = (0, undef, '');

    $client->request(sub {
        my ($response, $error) = @_;
        $done = 1;
        return $failed = $error if $error;
        printf "%d, %d bytes\n", $response->getinfo(CURLINFO_RESPONSE_CODE), length $body;
    }, {
        CURLOPT_URL => 'https://www.perl.org',
        CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
        CURLOPT_HTTPHEADER => ['My-Super-Awesome-Header: forty-two'],
    });

    EV::run until $done;
    die "Request failed: $failed\n" if $failed;

=head1 DESCRIPTION

This module binds libcurl's L<"multi" interface|https://curl.se/libcurl/c/libcurl-multi.html>
to L<EV>. Transfers run on EV's default loop alongside everything else it drives, and
libcurl's sockets and timeouts are managed by C watchers registered directly through
EV's C API, without a round trip through Perl.

=head1 METHODS

=head2 EV::YACurl

=over

=item C<new>

    my $client = EV::YACurl->new(\%options);

Returns a new client, which is a binding over one curl multi handle. The required
hashref holds C<CURLM*> options such as C<CURLMOPT_MAX_TOTAL_CONNECTIONS>; see the
L<curl documentation|https://curl.se/libcurl/c/curl_multi_setopt.html> for the full
list. Options this module cannot translate are rejected rather than silently
ignored, as are names belonging to another namespace: the numbers collide, so a
C<CURLOPT_*> name here would otherwise set an unrelated multi option.

A client owns a connection pool, so reusing one across requests is what enables
keep alive and HTTP/2 multiplexing.

=item C<request>

    $client->request($callback, \%options);

Starts a request. C<%options> holds C<CURLOPT_*> options and must contain at least
C<CURLOPT_URL>; see the L<curl documentation|https://curl.se/libcurl/c/curl_easy_setopt.html>.

Returns nothing. C<$callback> is invoked once the request finishes, with two
arguments, C<$response> and C<$error>, exactly one of which is defined. C<$response>
is an L</"EV::YACurl::Response"> object; C<$error> is a human readable description
of what went wrong, taken from libcurl's error buffer when it has something more
specific to say than the generic message for the error code.

The client is kept alive for the duration of the request, so it is safe to let the
last reference to it go out of scope while transfers are in flight.

A callback that dies does not propagate: the exception is caught and reported as
a warning, and the loop carries on. Record what went wrong and act on it after
C<EV::run> returns, as the synopsis does, rather than dying inside the callback.

Start follow-up requests from this completion callback. C<request> croaks when
called from inside a per-request data callback (C<CURLOPT_WRITEFUNCTION> and
friends), for any client, because libcurl is inside its own API while those
run; the croak is reported as a warning like any other callback death. Do not
run a nested event loop from one either, for the same reason.

A request that fails before it reaches the network, a malformed URL for
instance, is finished before C<request> returns, so its callback runs on the
caller's stack rather than from the loop. A callback that retries such a
request unconditionally therefore recurses instead of unwinding; bound the
retries, or arm an C<EV::timer> and retry from that.

=item C<priority>

    my $current  = $client->priority;
    my $previous = $client->priority($new_priority);

Queries, and optionally sets, the EV priority of every watcher this client owns:
the C<ev_io> watcher behind each socket libcurl asks to poll, and the client's
C<ev_timer>. Values outside C<EV::MINPRI> .. C<EV::MAXPRI> are clamped. Returns
the priority that was in effect before the call.

libcurl invokes the per request callbacks (C<CURLOPT_WRITEFUNCTION> and friends,
and the completion callback given to C<request>) synchronously from inside those
watchers, so this is also the priority at which your callbacks run.

Priority belongs to the client rather than to an individual request, because one
socket can carry several transfers at once under keep alive and HTTP/2
multiplexing. To run two groups of transfers at different priorities, use two
clients.

Setting it takes effect immediately, including on watchers the client already
owns. A watcher that has already received an event keeps its old priority for
that one event, since re-sorting it would discard the event; the new priority
reaches it as soon as that event has been dispatched.

=item C<default_priority>

    my $current  = EV::YACurl->default_priority;
    my $previous = EV::YACurl->default_priority($new_priority);

Class method. Queries, and optionally sets, the priority handed to clients created
from now on. Defaults to C<0>, which is EV's own default. Existing clients are not
affected, so set this during startup rather than mid run.

=back

=head2 EV::YACurl::Response

=over

=item C<getinfo>

    my $value = $response->getinfo(CURLINFO_RESPONSE_CODE);

Queries libcurl for information about the finished transfer. See the
L<curl documentation|https://curl.se/libcurl/c/curl_easy_getinfo.html> for the
available C<CURLINFO_*> options.

String, integer and floating point results come back as plain scalars, and the
ones that return a C<curl_slist>, C<CURLINFO_COOKIELIST> for instance, come
back as an array reference of strings. The remaining kinds, the ones handing
out C pointers and sockets, are refused.

=back

=head1 CURL OPTIONS

Some translation between Perl and curl value types has to be done. Options taking a
number or a string are converted from plain scalars. Options taking a C<curl_slist>
take an array reference instead, as C<CURLOPT_HTTPHEADER> does in the synopsis.
C<CURLOPT_MIMEPOST> takes an array of hashrefs, each with a C<name> and one of
C<value> or C<file>.

C<CURLOPT_POSTFIELDS> is copied by libcurl along with its length, so a body
containing zero bytes survives; there is no need to set C<CURLOPT_POSTFIELDSIZE>
yourself.

Each request is its own libcurl easy handle, which is what a cookie jar is
flushed from. A C<CURLOPT_COOKIEJAR> file is therefore not written until the
response object is freed, so a follow-up request started from inside the
completion callback will not see it yet: carry the cookie across yourself with
C<CURLOPT_COOKIE>, or start the follow-up after the response has gone.

Options that take a function need a Perl signature of their own, documented below.

=over

=item CURLOPT_WRITEFUNCTION

(See L<curl documentation|https://curl.se/libcurl/c/CURLOPT_WRITEFUNCTION.html>)

Called with the received data as its only argument. Its return value is
ignored, so it cannot abort a transfer; use C<CURLOPT_TIMEOUT_MS> and friends,
or return C<undef> from C<CURLOPT_READFUNCTION> on an upload.

    CURLOPT_WRITEFUNCTION => sub {
        my ($data) = @_;
        print STDERR $data;
    },

=item CURLOPT_HEADERFUNCTION

(See L<curl documentation|https://curl.se/libcurl/c/CURLOPT_HEADERFUNCTION.html>)

Called with one header line at a time, as received.

=item CURLOPT_READFUNCTION

(See L<curl documentation|https://curl.se/libcurl/c/CURLOPT_READFUNCTION.html>)

Called with the maximum number of bytes wanted. Return the data, an empty string
to end the transfer, or C<undef> to abort it.

    CURLOPT_READFUNCTION => sub {
        my ($length) = @_;
        return substr($my_data, 0, $length, '');
    },

=item CURLOPT_DEBUGFUNCTION

(See L<curl documentation|https://curl.se/libcurl/c/CURLOPT_DEBUGFUNCTION.html>)

Called with a C<CURLINFO_*> type and the data itself.

    CURLOPT_DEBUGFUNCTION => sub {
        my ($type, $data) = @_;
        print STDERR "curl: $data\n" if $type == CURLINFO_TEXT;
    },

=item CURLOPT_TRAILERFUNCTION

(See L<curl documentation|https://curl.se/libcurl/c/CURLOPT_TRAILERFUNCTION.html>)

Called without arguments. Return an array reference of trailing headers to send,
or C<undef> to abort the request.

    CURLOPT_TRAILERFUNCTION => sub {
        return ['My-super-awesome-trailer: trailer-stuff'];
    },

=item CURLOPT_STDERR

(See L<curl documentation|https://curl.se/libcurl/c/CURLOPT_STDERR.html>)

Takes a file descriptor number rather than a filehandle, and duplicates it so
the destination stays valid for the whole transfer.

    CURLOPT_STDERR => fileno($fh),

=back

C<CURLOPT_PRIVATE> and C<CURLOPT_ERRORBUFFER> are used internally and cannot be set.

=head1 REQUIREMENTS

libcurl 7.64.0 or newer, built with AsynchDNS. Without AsynchDNS every name
lookup blocks the event loop, which defeats the point of an asynchronous
binding; C<Makefile.PL> warns when it can tell that support is missing.

=head1 CAVEATS

Transfers run on EV's default loop.

Letting the last reference to a busy client go is safe, since its transfers
hold it up until they finish. Tearing one down by hand while transfers are
still in flight is not: it warns, abandons them, and what they were holding
is only reclaimed when the process exits.

Clients and responses belong to the interpreter that created them and are not
cloned into new threads: after C<< threads->create >> they read as C<undef>
there. Create new ones in the new thread.

A client does not survive a fork, and the hazard is the child's exit rather
than its use: tearing libcurl down closes connections the parent is still
using. Create clients after forking, and let forked children leave through
C<POSIX::_exit> so they never run that teardown.

=head1 EXAMPLES

The C<eg/> directory in the distribution has runnable programs for the common
shapes: a single request (C<get.pl>), many at once through one connection pool
(C<concurrent.pl>), streaming a response to disk (C<download.pl>), sending a
file with a read callback (C<upload.pl>), request and response headers with the
transfer's timings (C<headers.pl>), and placing transfers in EV's priority
order alongside a latency-sensitive watcher (C<priority.pl>).

Further in: a JSON API call that carries a session into a second request
(C<json-api.pl>), a multipart upload (C<multipart.pl>), retrying with backoff
on an EV timer (C<retry.pl>), per-request deadlines and cancelling an upload
mid-flight (C<timeout.pl>), draining in-flight work on a signal
(C<shutdown.pl>), and HTTP/2 multiplexing measured against one connection per
transfer (C<http2.pl>).

=head1 SEE ALSO

L<EV>, L<AnyEvent::YACurl>

=head1 ACKNOWLEDGEMENTS

This distribution is a fork of L<AnyEvent::YACurl> 0.22 by Tom van der Woerdt,
and would not exist without it. Everything that makes the binding useful came
from there: the mapping of the whole C<CURLOPT_*> table onto Perl values, the
generators that keep that table in step with libcurl's headers, the callback
marshalling for C<CURLOPT_WRITEFUNCTION> and its siblings, the MIME and slist
handling, and the response object.

What this fork changes is the event integration. Where AnyEvent::YACurl asks
AnyEvent for watchers from Perl, EV::YACurl creates C<ev_io> and C<ev_timer>
watchers from XS through EV's C API, which is what makes C<priority> possible
and what keeps Perl out of the per-socket path.

=head1 AUTHOR

vividsnow

Original AnyEvent::YACurl by Tom van der Woerdt <tvdw@cpan.org>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
