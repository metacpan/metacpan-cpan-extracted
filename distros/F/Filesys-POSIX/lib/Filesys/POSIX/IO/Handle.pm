# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::IO::Handle;

use strict;
use warnings;

use Fcntl qw(SEEK_CUR);
use Filesys::POSIX::Bits;
use Filesys::POSIX::Bits::System;

=head1 NAME

Filesys::POSIX::IO::Handle - Basic wrapper for Perl file handles

=head1 DESCRIPTION

This package provides a wrapper for standard Perl file handles.  It is not meant
to supplant the behavior or necessity of L<IO::Handle>; rather, it is meant to
provide a base reference for all of the I/O operations supported by
L<Filesys::POSIX>, which ignores concerns such as buffering and the like.

=head1 METHODS

=over

=item C<Filesys::POSIX::IO::Handle-E<gt>new($fh)>

Returns a blessed reference to the file handle passed.

=cut

sub new {
    my ( $class, $fh ) = @_;

    return bless \$fh, $class;
}

=item C<$handle-E<gt>write($buf, $len)>

Calls L<perlfunc/syswrite> on the current file handle, passing the C<$buf> and
C<$len> arguments literally.  Returns the result of L<perlfunc/syswrite>.

=cut

sub write {
    my ( $self, $buf, $len ) = @_;

    return syswrite( $$self, $buf, $len );
}

=item C<$handle-E<gt>print(@args)>

Prints a concatenation of each item passed, joined by C<$/>, to the current file
handle.

=cut

sub print {
    my ( $self, @args ) = @_;
    my $buf = join( $/, @args );

    return $self->write( $buf, length $buf );
}

=item C<$handle-E<gt>sprintf($format, @args)>

Prints a formatted string to the current file handle.  Uses L<perlfunc/sprintf>.

=cut

sub printf {
    my ( $self, $format, @args ) = @_;
    my $buf = sprintf( $format, @args );

    return $self->write( $buf, length $buf );
}

=item C<$handle-E<gt>read($buf, $len)>

Reads C<$len> bytes from C<$handle> into C<$buf>.

=cut

sub read {
    my $self = shift;
    my $len  = pop;

    return sysread( $$self, $_[0], $len );
}

=item C<$handle-E<gt>seek($pos, $whence)>

Seek C<$handle> to C<$pos> bytes, relative to the current byte position,
according to the seek mode listed in C<$whence>.  C<$whence> is a position
modifier as specified in L<Filesys::POSIX::Bits>.

=cut

sub seek {
    my ( $self, $pos, $whence ) = @_;

    return sysseek(
        $$self, $pos,
        Filesys::POSIX::Bits::System::convertWhenceToSystem($whence)
    );
}

=item C<$handle-E<gt>tell>

Returns the current absolute byte position of the current file C<$handle>.

=cut

sub tell {
    my ($self) = @_;

    return sysseek( $$self, 0, SEEK_CUR );
}

=item C<$handle-E<gt>close>

Close the current file handle.

=cut

sub close {
    my ($self) = @_;

    close $$self;
}

=back

=head1 SEE ALSO

=over

=item L<Filesys::POSIX::Mem::Bucket>

Provides an implementation of the interface described herein, but for access to
regular file data for L<Filesys::POSIX::Mem> filesystem hierarchies.

=back

=cut

1;

__END__

=head1 AUTHOR

Written by Xan Tronix <xan@cpan.org>

=head1 CONTRIBUTORS

=over

=item Rikus Goodell <rikus.goodell@cpanel.net>

=item Brian Carlson <brian.carlson@cpanel.net>

=back

=head1 COPYRIGHT

Copyright (c) 2014, cPanel, Inc.  Distributed under the terms of the Perl
Artistic license.
