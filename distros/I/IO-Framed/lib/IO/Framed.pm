package IO::Framed;

use strict;
use warnings;

our $VERSION = '0.021';

=encoding utf-8

=head1 NAME

IO::Framed - Convenience wrapper for frame-based I/O

=head1 SYNOPSIS

Reading:

    #See below about seed bytes.
    my $reader = IO::Framed::Read->new( $in_fh, 'seed bytes' );

    #This returns undef if the $in_fh doesn’t have at least
    #the given length (5 in this case) of bytes to read.
    $frame = $reader->read(5);

Writing, unqueued (i.e., for blocking writes):

    my $writer = IO::Framed::Write->new( $out_fh );

    #The second parameter (if given) is executed immediately after the final
    #byte of the payload is written. For blocking I/O this happens
    #before the following method returns.
    $writer->write('hoohoo', sub { print 'sent!' } );

Writing, queued (for non-blocking writes):

    $writer->enable_write_queue();

    #This just adds to a memory queue:
    $writer->write('hoohoo', sub { print 'sent!' } );

    #This will be 1, since we have 1 message/frame queued to send.
    $writer->get_write_queue_count();

    #Returns 1 if it empties out the queue; 0 otherwise.
    #Partial frame writes are accommodated; the callback given as 2nd
    #argument to write() only fires when the queue item is sent completely.
    my $empty = $writer->flush_write_queue();

You can also use C<IO::Framed::ReadWrite>, which combine the
features of the read and write modules above.

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
    $framed->read(10);

    #… wait for readiness if non-blocking …

    #XXX This die()s because we’re in the middle of trying to read
    #10 bytes, not 4.
    $framed->read(4);

    #If this completes the read (i.e., takes in 8 bytes), then it’ll
    #return the full 10 bytes; otherwise, it’ll return undef again.
    $framed->read(10);

EINTR prompts a redo of the read operation. EAGAIN and EWOULDBLOCK (the same
error generally, but not always) prompt an undef return.
Any other failures prompt an instance of L<IO::Framed::X::ReadError> to be
thrown.

=head1 ABOUT WRITES

Writes for blocking I/O are straightforward: the system will always send
the entire buffer. The OS’s C<write()> won’t return until everything
meant to be written is written. Life is pleasant; life is simple. :)

Non-blocking I/O is trickier. Not only can the OS’s C<write()> only write
a portion of the data it’s given, but we also can’t know that the output
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

=head1 ERROR RESPONSES

An empty read or any I/O error besides the ones mentioned previously
are indicated via an instance of one of the following exceptions.

All exceptions subclass L<X::Tiny::Base>.

=over

=item L<IO::Frame::X::ReadError>

=item L<IO::Frame::X::WriteError>

These both have an C<OS_ERROR> property (cf. L<X::Tiny::Base>’s accessor
method).

=item L<IO::Frame::X::EmptyRead>

No properties. If this is thrown, your peer has probably closed the connection.
You probably should thus always trap this exception.

=back

B<NOTE:> This distribution doesn’t write to C<$!>.

=head1 LEGACY CLASSES

This distribution also includes the following B<DEPRECATED> legacy classes:

=over

=item * IO::Frame::Write::Blocking

=item * IO::Frame::Write::NonBlocking

=item * IO::Frame::ReadWrite::Blocking

=item * IO::Frame::ReadWrite::NonBlocking

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

1;
