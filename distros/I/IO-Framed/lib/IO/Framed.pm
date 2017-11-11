package IO::Framed;

use strict;
use warnings;

our $VERSION = '0.031';

=encoding utf-8

=head1 NAME

IO::Framed - Convenience wrapper for frame-based I/O

=head1 SYNOPSIS

Reading:

    #See below about seed bytes.
    my $iof = IO::Framed->new( $fh, 'seed bytes' );

    #This returns undef if the $in_fh doesn’t have at least
    #the given length (5 in this case) of bytes to read.
    $frame = $iof->read(5);

Writing, unqueued (i.e., for blocking writes):

    #The second parameter (if given) is executed immediately after the final
    #byte of the payload is written. For blocking I/O this happens
    #before the following method returns.
    $iof->write('hoohoo', sub { print 'sent!' } );

Writing, queued (for non-blocking writes):

    $iof->enable_write_queue();

    #This just adds to a memory queue:
    $iof->write('hoohoo', sub { print 'sent!' } );

    #This will be 1, since we have 1 message/frame queued to send.
    $iof->get_write_queue_count();

    #Returns 1 if it empties out the queue; 0 otherwise.
    #Partial frame writes are accommodated; the callback given as 2nd
    #argument to write() only fires when the queue item is sent completely.
    my $empty = $iof->flush_write_queue();

You can also use C<IO::Framed::Read> and C<IO::Framed::Write>, which
contain just the read and write features. (C<IO::Framed> is actually a
subclass of them both.)

=head1 DESCRIPTION

While writing L<Net::WAMP> I noticed that I was reimplementing some of the
same patterns I’d used in L<Net::WebSocket> to parse frames from a stream:

=over

=item * Only read() entire frames, with a read queue for any partials.

=item * Continuance when a partial frame is delivered.

=item * Write queue with callbacks for non-blocking I/O

=item * Signal resilience: resume read/write after Perl receives a trapped
signal rather than throwing/giving EINTR. (cf. L<IO::SigGuard>)

=back

These are now made available in this distribution.

=head1 ABOUT READS

The premise here is that you expect a given number of bytes at a given time
and that a partial read should be continued once it is sensible to do so.

As a result, C<read()> will throw an exception if the number of bytes given
for a continuance is not the same number as were originally requested.

Example:

    #This reads only 2 bytes, so read() will return undef.
    $iof->read(10);

    #… wait for readiness if non-blocking …

    #XXX This die()s because we’re in the middle of trying to read
    #10 bytes, not 4.
    $iof->read(4);

    #If this completes the read (i.e., takes in 8 bytes), then it’ll
    #return the full 10 bytes; otherwise, it’ll return undef again.
    $iof->read(10);

EINTR prompts a redo of the read operation. EAGAIN and EWOULDBLOCK (the same
error generally, but not always) prompt an undef return.
Any other failures prompt an instance of L<IO::Framed::X::ReadError> to be
thrown.

=head2 EMPTY READS

This class’s C<read()> method will, by default, throw an instance of
L<IO::Framed::X::EmptyRead> on an empty read. This is normal and logical
behavior in contexts (like L<Net::WebSocket>) where the data stream itself
indicates when no more data will come across. In such cases an empty read
is genuinely an error condition: it either means you’re reading past when
you should, or the other side prematurely went away.

In some other cases, though, that empty read is the normal and expected way
to know that a filehandle/socket has no more data to read.

If you prefer, then, you can call the C<allow_empty_read()> method to switch
to a different behavior, e.g.:

    $framed->allow_empty_read();

    my $frame = $framed->read(10);

    if (length $frame) {
        #yay, we got a frame!
    }
    elsif (defined $frame) {
        #no more data will come in, so let’s close up shop
    }
    else {
        #undef means we just haven’t gotten as much data as we want yet;
        #in this case, that means fewer than 10 bytes are available.
    }

Instead of throwing the aforementioned exception, C<read()> now returns
empty-string on an empty read. That means that you now have to distinguish
between multiple “falsey” states: undef for when the requested number
of bytes hasn’t yet arrived, and empty string for when no more bytes
will ever arrive. But it is also true now that the only exceptions thrown
are bona fide B<errors>, which will suit some applications better than the
default behavior.

NB: If you want to be super-light, you can bring in IO::Framed::Read instead
of the full IO::Framed. (IO::Framed is already pretty lightweight, though.)

=head1 ABOUT WRITES

Writes for blocking I/O are straightforward: the system will always send
the entire buffer. The OS’s C<write()> won’t return until everything
meant to be written is written. Life is pleasant; life is simple. :)

Non-blocking I/O is trickier. Not only can the OS’s C<write()> write
a subset of the data it’s given, but we also can’t know that the output
filehandle is ready right when we want it. This means that we have to queue up
our writes
then write them once we know (e.g., through C<select()>) that the filehandle
is ready. Each C<write()> call, then, enqueues one new buffer to write.

Since it’s often useful to know when a payload has been sent,
C<write()> accepts an optional callback that will be executed immediately
after the last byte of the payload is written to the output filehandle.

Empty out the write queue by calling C<flush_write_queue()> and looking for
a truthy response. (A falsey response means there is still data left in the
queue.) C<get_write_queue_count()> gives you the number of queue items left
to write. (A partially-written item is treated the same as a fully-unwritten
one.)

Note that, while it’s acceptable to activate and deactive the write queue,
the write queue must be empty in order to deactivate it. (You’ll get a
nasty, untyped exception otherwise!)

C<write()> returns undef on EAGAIN and EWOULDBLOCK. It retries on EINTR,
so you should never actually see this error from this module.
Other errors prompt a thrown exception.

NB: C<enable_write_queue()> and C<disable_write_queue()> return the object,
so you can instantiate thus:

    my $nb_writer = IO::Framed::Write->new($fh)->enable_write_queue();

NB: If you want to be super-light, you can bring in IO::Framed::Write instead
of the full IO::Framed. (IO::Framed is already pretty lightweight, though.)

=head1 ERROR RESPONSES

An empty read or any I/O error besides the ones mentioned previously
are indicated via an instance of one of the following exceptions.

All exceptions subclass L<X::Tiny::Base>.

=over

=item L<IO::Framed::X::ReadError>

=item L<IO::Framed::X::WriteError>

These both have an C<OS_ERROR> property (cf. L<X::Tiny::Base>’s accessor
method).

=item L<IO::Framed::X::EmptyRead>

No properties. If this is thrown, your peer has probably closed the connection.
Unless you have called C<allow_empty_read()> to set an alternate behavior,
you might want to trap this exception if you call C<read()>.

=back

B<NOTE:> This distribution doesn’t write to C<$!>. EAGAIN and EWOULDBLOCK on
C<flush_write_queue()> are ignored; all other errors are converted
to thrown exceptions.

=cut

use parent qw(
    IO::Framed::Read
    IO::Framed::Write
);

sub new {
    my ( $class, $in_fh, $out_fh, $initial_buffer ) = @_;

    my $self = $class->SUPER::new( $in_fh, $initial_buffer );

    $self->{'_out_fh'} = $out_fh || $in_fh,

    return (bless $self, $class)->disable_write_queue();
}

1;

=head1 LEGACY CLASSES

This distribution also includes the following B<DEPRECATED> legacy classes:

=over

=item * IO::Framed::Write::Blocking

=item * IO::Framed::Write::NonBlocking

=item * IO::Framed::ReadWrite

=item * IO::Framed::ReadWrite::Blocking

=item * IO::Framed::ReadWrite::NonBlocking

=back

I’ll keep these in for the time being but eventually B<WILL> remove them.
Please adjust any calling code that you might have.

=head1 REPOSITORY

L<https://github.com/FGasper/p5-IO-Framed>

=head1 AUTHOR

Felipe Gasper (FELIPE)

=head1 COPYRIGHT

Copyright 2017 by L<Gasper Software Consulting, LLC|http://gaspersoftware.com>

=head1 LICENSE

This distribution is released under the same license as Perl.

=cut
