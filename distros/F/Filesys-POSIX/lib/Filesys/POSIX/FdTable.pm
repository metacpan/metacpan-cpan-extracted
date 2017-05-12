# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::FdTable;

use strict;
use warnings;

use Filesys::POSIX::Error qw(throw);

=head1 NAME

Filesys::POSIX::FdTable - File descriptor table

=head1 DESCRIPTION

This internal module used by Filesys::POSIX handles the allocation and tracking
of numeric file descriptors associated with inodes opened for I/O.  It does not
intend to expose any public interfaces.

=head1 METHODS

=over

=item C<Filesys::POSIX::FdTable-E<gt>new>

Create a new file descriptor table object.  Returns a blessed hash.

=cut

sub new {
    return bless {}, shift;
}

=item C<$fd_table-E<gt>open($inode, $flags)>

Asks the C<$inode> object to open and return a L<Filesys::POSIX::IO::Handle>
object.  Accepts flags as defined in L<Filesys::POSIX::Bits>.  A reference to
the inode, file handle, flags passed will be stored.

Returns a unused file descriptor number greater than 2, unique to the current
file descriptor table, upon success.  Possible exceptions may be thrown:

=over

=item * ENODEV (No such device or address)

Could not open a file handle for the inode passed.

=back

=cut

sub open {
    my ( $self, $inode, $flags ) = @_;

    my $fd     = 2;
    my $handle = $inode->open($flags);

    $! = 0;

    throw &Errno::ENODEV unless $handle;

    foreach ( sort { $a <=> $b } ( $fd, keys %$self ) ) {
        next if $self->{ $fd = $_ + 1 };
        last;
    }

    $self->{$fd} = {
        'inode'  => $inode,
        'handle' => $handle,
        'flags'  => $flags
    };

    return $fd;
}

=item C<$fd_table-E<gt>lookup($fd)>

Given a file descriptor number, return the file descriptor table entry stored;
such an object contains an inode reference, a file handle reference, and the
flags with which the file was opened.  Possible exceptions include:

=over

=item * EBADF (Bad file descriptor)

No handle found for the given file descriptor.

=back

=cut

sub lookup {
    my ( $self, $fd ) = @_;

    $! = 0;

    my $entry = $self->{$fd} or throw &Errno::EBADF;

    return $entry;
}

=item C<$fd_table-E<gt>close($fd)>

Close the file handle corresponding to the given file descriptor, and remove the
file descriptor from the table, freeing it for future reallocation.

=cut

sub close {
    my ( $self, $fd ) = @_;
    my $entry = $self->{$fd} or return;

    $entry->{'handle'}->close;

    delete $self->{$fd};
}

=item C<$fd_table-E<gt>list>

Return a list of all file descriptor numbers currently allocated.

=cut

sub list {
    my ($self) = @_;

    return keys %$self;
}

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
