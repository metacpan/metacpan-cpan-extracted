package IO::Mark;

use warnings;
use strict;
use Carp;
use IO::Mark::Buffer;
use IO::Mark::SlaveBuffer;

use base qw(IO::Handle);

use version; our $VERSION = qv( '0.0.1' );

sub new {
    my ( $class, $fh ) = @_;

    my $self = $class->SUPER::new;

    # Make sure the handle we're cloning has the caching layer installed
    IO::Mark::Buffer::_upgrade_handle( $fh );

    my $key  = IO::Mark::Buffer::_cache_key( $fh );

    open( $self, "<:via(IO::Mark::SlaveBuffer)", $key ) or die "Can't open ($!)";
    
    return $self;
}

1;
__END__

=head1 NAME

IO::Mark - Read unseekable filehandles non-destructively.

=head1 VERSION

This document describes IO::Mark version 0.0.1

=head1 SYNOPSIS

    use IO::Mark;

    sub examine {
        my $fh = shift;
        
        my $mark = IO::Mark->new( $fh );
        my $buf;

        # Reads from $fh via $mark
        $mark->read( $buf, 1000, 0 );
        
        # Do something with $buf
        
        # When $mark goes out of scope $fh no data will appear to have
        # been consumed from $fh
    }

=head1 DESCRIPTION

This is alpha quality code. It's slow. It may have bugs.

Imagine you've got a function C<get_image_size>. You pass it a
filehandle that's open on an image file and it returns the dimensions
of the image.

Imagine also that you have an open socket on which you are expecting to
receive an image. You'd like to know the dimensions of that image and
also capture its data.

If you pass the socket handle to C<get_image_size> it'll consume some
data from that socket - enough to read the image header and work out its
dimensions. Unfortunately any data that C<get_image_size> reads is lost;
you know the dimensions of the image but you've lost some of its data
and you can't rewind the socket to go back to the start of the image;
sockets aren't seekable.

    sub send_image {
        my $socket = shift;
        
        # This works fine...
        my ($width, $height) = get_image_size( $socket );

        # ...but the data we send here will be missing whatever header
        # bytes get_image_size consumed.
        send_image_data( $width, $height, $socket );
    }

You could buffer the entire image in a file, open the file and pass that
handle to C<get_image_size>. That works but means that we can't compute
the image size until we have the whole image. If instead of an image
file we were dealing with streaming audio the input stream might be
effectively infinite - which would make caching it in a file
inconvenient.

We could rewrite C<get_image_size> to cache whatever data it reads from
the socket. Then we could send that data before sending the remainder of
the data from the socket. That probably means digging around inside a
function we didn't write and coupling its interface tightly to our
application. It'd be good to avoid that.

Here's the solution:

    use IO::Mark;

    sub send_image {
        my $socket = shift;

        my $mark = IO::Mark->new( $socket );

        # This works fine...
        my ($width, $height) = get_image_size( $mark );
        
        $mark->close;

        # ... and so does this!
        send_image_data( $width, $height, $socket );
    }

An C<IO::Mark> is an L<IO::Handle> that returns data from the handle
from which it was created without consuming that data from the point of
view of the original handle.

Note the explicit call to C<close> once we're done with C<$mark>. As
long as the cloned C<IO::Mark> handle is in scope and open any data read
from the original handle will be buffered in memory in case it needs to
be read from the cloned handle too. To prevent this either explicitly
close the cloned handle or allow it to go out of scope.

=head1 INTERFACE

=over

=item C<< new( $fh ) >>

Create a clone of a filehandle. Reading data from the clone will not
advance the position of the original handle.

The original handle and any clones you have created will each maintain
an independent file pointer.

=back

=head1 CONFIGURATION AND ENVIRONMENT
  
IO::Mark requires no configuration files or environment variables.

=head1 DEPENDENCIES

Which Perl version?

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-io-mark@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
