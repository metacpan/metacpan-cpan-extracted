package Hyperman::Writer;

use strict;
use warnings;

our $VERSION = '0.46';

require Hyperman;   # all methods are XS (xs/writer.xs, include/hyperman/)

1;

__END__

=head1 NAME

Hyperman::Writer - the object that writes a response body a piece at a time

=head1 SYNOPSIS

    # from a psgi.streaming responder
    sub {
        my $env = shift;
        return sub {
            my $respond = shift;
            my $w = $respond->([ 200, [ 'Content-Type' => 'text/plain' ] ]);
            $w->write("a piece;");
            $w->write("another");
            $w->close;
        };
    }

    # or from the stream seam, which also works on HTTP/2 and on TLS
    sub {
        my $env = shift;
        return sub {
            my $w = Hyperman::stream($env, 200,
                        [ 'Content-Type' => 'text/plain' ]);
            $w->write($_) for @chunks;
            $w->close;
        };
    }

=head1 DESCRIPTION

Two methods and one promise: what you write goes out in order, and when you
close it the body has ended. You never construct one - it comes back from a
C<psgi.streaming> responder or from L<Hyperman/stream>.

Underneath there are three transports, and a writer is a blessed arrayref
whose shape says which:

=over 4

=item * an EOF-delimited HTTP/1.1 connection, where closing the body closes
the socket (there is no chunked response encoding: the response carries
C<Connection: close> and the client reads to end of file);

=item * an HTTP/2 stream, buffered until close and then submitted as one
response;

=item * an ABI v6 stream handle, which is the transport-neutral one. The same
three calls write over HTTP/1.1 or over an HTTP/2 stream, in clear or under
TLS, and the branch lives inside the handle rather than in the caller. This
is what L<Hyperman/stream> hands back.

=back

Three shapes rather than three classes, because they are one contract. Code
holding a writer never has to ask which it has.

=head1 METHODS

=head2 write

    $w->write($bytes);

Append to the body. The bytes are copied, so the caller may reuse its buffer.

Writing to a stream whose connection has gone is dropped rather than fatal:
by then the reader is already lost, and a producer looping over rows has
nothing useful to do with an exception. A C consumer that does want to know -
to stop a query, or to release a subscription - gets the reason from the C
ABI's C<stream_write> instead, along with the backpressure signal that says
when to pause. See L<Hyperman/Stream handles>.

=head2 close

    $w->close;

End the body. On HTTP/1.1 that closes the connection, because the response
was EOF-delimited; on HTTP/2 it ends that stream and leaves the connection
serving its others.

Closing twice is harmless. A writer that goes out of scope without being
closed is closed then, the way a lexical filehandle is - but close it
yourself where you can, so the body ends when you meant it to and not when
the last reference happens to go.

=head2 abort

    $w->abort;

End the body so the client can tell it was B<not> finished. Use it where the
producer failed part way - the query died, the source went away - and the
bytes already sent are not a whole response.

C<close> is the wrong answer there and quietly so. A streamed body has no
declared length, so there is nothing for the client to check: a body that
stops early and ends cleanly arrives as a complete short one, which is the
export that silently lost its last thousand rows. What the client needs is to
be told, and that is a different signal on each transport - C<RST_STREAM>
with C<INTERNAL_ERROR> on HTTP/2, killing this stream and leaving the
connection's others alone, and a connection reset on HTTP/1.1, where the
graceful close is itself the success signal and a reset is the only thing
distinguishable from it. Output still queued is discarded on HTTP/1.1; that
is the price of being able to say so at all.

Returns 0 when the stream was aborted, or a negative value when there was
nothing live to abort - C<-2> for a stream whose connection had already gone,
C<-1> for a writer that is not the stream-handle shape (the older
C<psgi.streaming> writers have no such verb, and are left alone rather than
being closed gracefully behind your back).

Call C<abort> or C<close>, never both.

=head1 SEE ALSO

L<Hyperman>, and L<Hyperman/stream> for the seam that returns a
transport-neutral writer.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
