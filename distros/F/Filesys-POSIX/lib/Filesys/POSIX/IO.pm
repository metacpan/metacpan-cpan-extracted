# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::IO;

use strict;
use warnings;

use Filesys::POSIX::Bits;
use Filesys::POSIX::Module  ();
use Filesys::POSIX::FdTable ();
use Filesys::POSIX::Path    ();
use Filesys::POSIX::Error qw(throw);

my @MODULES = qw(open read write print printf tell seek close fdopen);

Filesys::POSIX::Module->export_methods( __PACKAGE__, @MODULES );

=head1 NAME

Filesys::POSIX::IO - Provides file I/O calls for L<Filesys::POSIX>

=head1 DESCRIPTION

C<Filesys::POSIX::IO> is a mixin imported into the Filesys::POSIX namespace by
the L<Filesys::POSIX> module itself.  This module provides the standard file I/O
routines.

=over

=item C<$fs-E<gt>open($path, $flags)>

=item C<$fs-E<gt>open($path, $flags, $mode)>

Open a file descriptor for an inode specified by $path.  This operation can be
modified by usage of the following flags which can be specified together using
logical OR (|).  The flags as follows are exported by L<Filesys::POSIX::Bits>:

=over

=item C<$O_CREAT>

If an inode at the specified path does not exist, attempt to create one.

When a mode is specified, the value is split into the format (C<$S_IFMT>),
permission (C<$S_IPERM>), and protection (C<$S_IPROT>) bitfields.  If no
value was specified for the format, then the default value of C<$S_IFREG>
(regular file) is substituted.  

When no mode is specified whatsoever, the default values of an C<$S_IFREG>
format, and a mode of 0666 are used, modified by the current umask value.

In either case, the permissions to be used are modified with an exclusive OR
operation by the current umask value.

=item C<$O_EXCL>

When specified in the presence of C<$O_CREAT>, the call will only succeed when
the path lists a nonexisting inode.  A "File exists" exception will be thrown if
this is not the case.

=item C<$O_TRUNC>

When specified, any existing file data will be truncated, and the file handle
position will start at offset 0 (zero).

=item C<$O_APPEND>

When specified, the file handle position will start at the offset value equal
to the size of the file.

=item C<$O_RDONLY>

The default flag field value.  When neither C<$O_WRONLY> nor C<$O_RDWR> are
specified, any write operations will be prohibited on the newly issued file
descriptor.

=item C<$O_WRONLY>

When specified, any read operations will be prohibited on the newly issued file
descriptor.

=item C<$O_RDWR>

When specified, both read and write operations will be allowed on the newly
issued file descriptor.

=back

The following exceptions may be thrown.

=over

=item * EINVAL (Invalid argument)

No flags were specified in I<$flags>.

=item * EEXIST (File exists)

When the C<$O_CREAT> flag is passed, this error may occur if a file located at
I<$path> already exists.

=back

=cut

sub open {
    my ( $self, $path, $flags, $mode ) = @_;
    my $hier = Filesys::POSIX::Path->new($path);
    my $name = $hier->basename;
    my $inode;

    throw &Errno::EINVAL unless defined $flags;

    if ( $flags & $O_CREAT ) {
        my $parent    = $self->stat( $hier->dirname );
        my $directory = $parent->directory;

        if ( $inode = $directory->get($name) ) {
            throw &Errno::EEXIST if $flags & $O_EXCL;
        }
        else {
            my $format =
              $mode
              ? ( $mode & $S_IFMT ? $mode & $S_IFMT : $S_IFREG )
              : $S_IFREG;
            my $perms = $mode ? $mode & ( $S_IPERM | $S_IPROT ) : $S_IRW;

            $perms &= ~$self->{'umask'};

            $inode = $parent->child( $name, $format | $perms );
        }
    }
    else {
        $inode = $self->stat($path);
    }

    return $self->{'fds'}->open( $inode, $flags );
}

=item C<$fs-E<gt>read($fd, $buf, $len)>

Perform a read on the file descriptor passed, storing at maximum the number of
bytes specified in C<$len>, into C<$buf>.  Returns the number of bytes actually
read; fewer bytes may be read than requested if the expected amount of data from
the current file handle position, plus the requested length, does not
match the requested length, such as when the length exceeds the end of the file
stream.  Returns zero if no more data is available to be read.

Exceptions are thrown for the following:

=over

=item * EINVAL (Invalid argument)

A read was attempted on a write-only file descriptor.

=back

=cut

sub read {
    my $self  = shift;
    my $fd    = shift;
    my $entry = $self->{'fds'}->lookup($fd);

    throw &Errno::EBADF if $entry->{'flags'} & $O_WRONLY;

    return $entry->{'handle'}->read(@_);
}

=item C<$fs-E<gt>write($fd, $buf, $len)>

Perform a write on the file descriptor passed, writing at maximum the number of
bytes specified in C<$len> from C<$buf> to the open file.  Returns the number of
bytes actually written; fewer bytes may be written than requested if the buffer
does not contain enough, or if the underlying file handle implementation was
not able to write the full amount in the case of a L<Filesys::POSIX::IO::Handle>
object issued for an open L<Filesys::POSIX::Real::Inode> object.

The following exceptions may be thrown:

=over

=item * EINVAL (Invalid argument)

A write was attempted on a read-only file descriptor.

=back

=cut

sub write {
    my ( $self, $fd, $buf, $len ) = @_;
    my $entry = $self->{'fds'}->lookup($fd);

    throw &Errno::EINVAL unless $entry->{'flags'} & ( $O_WRONLY | $O_RDWR );

    return $entry->{'handle'}->write( $buf, $len );
}

=item C<$fs-E<gt>print($fd, @args)>

Works similarly to C<$fs-E<gt>write>.  Each argument is concatenated using the
current value of C<$/> (see L<perlvar>), and passed with the amalgamated value's
length to the underlying file handle's C<$handle-E<gt>write> call.

Exceptions may be thrown for the following:

=over

=item * EINVAL (Invalid argument)

Issued when called on a read-only file descriptor.

=back

=cut

sub print {
    my ( $self, $fd, @args ) = @_;
    my $entry = $self->{'fds'}->lookup($fd);

    throw &Errno::EINVAL unless $entry->{'flags'} & ( $O_WRONLY | $O_RDWR );

    my $buf = join( $/, @args );

    return $entry->{'handle'}->write( $buf, length $buf );
}

=item C<$fs-E<gt>printf($fd, $format, @args)>

Similar to C<$fs-E<gt>print>, this call allows writes formatted by
L<sprintf()|perlfunc/sprintf> to be made to the given file descriptor.

Exceptions are thrown for:

=over

=item * EINVAL (Invalid argument)

Issued when called on a read-only file descriptor.

=back

=cut

sub printf {
    my ( $self, $fd, $format, @args ) = @_;
    my $entry = $self->{'fds'}->lookup($fd);

    throw &Errno::EINVAL unless $entry->{'flags'} & ( $O_WRONLY | $O_RDWR );

    my $buf = sprintf( $format, @args );

    return $entry->{'handle'}->write( $buf, length $buf );
}

=item C<$fs-E<gt>tell($fd)>

Returns the byte offset of the file descriptor's file handle.

=cut

sub tell {
    my ( $self, $fd ) = @_;
    my $entry = $self->{'fds'}->lookup($fd);

    return $entry->{'handle'}->tell;
}

=item C<$fs-E<gt>seek($fd, $pos, $whence)>

Sets the byte offset of the file descriptor's file handle, relative to the
current offset as modified by the value specified in $whence.  $whence can be
used to specify how the new position will be set relative to the current offset
with the following values (in L<Filesys::POSIX::Bits>):

=over

=item C<$SEEK_SET>

The new offset of the file handle will be set to C<0 + $pos> bytes, or, relative
to the beginning of the file.  This sets the file handle to an absolute offset.

=item C<$SEEK_CUR>

The new offset of the file handle will be set to C<$cur + $pos> bytes, or,
relative to the current file handle offset.

=item C<$SEEK_END>

The new offset of the file will be set to C<$size + $pos> bytes, or, relative to
the end of the file.

=back

=cut

sub seek {
    my ( $self, $fd, $pos, $whence ) = @_;
    my $entry = $self->{'fds'}->lookup($fd);

    return $entry->{'handle'}->seek( $pos, $whence );
}

=item C<$fs-E<gt>close($fd)>

Close the file handle issued for the given file descriptor, and deallocate said
file descriptor.  The file descriptor will then be freed for subsequent use and
issue by C<$fs-E<gt>open>.

=cut

sub close {
    my ( $self, $fd ) = @_;
    $self->{'fds'}->close($fd);
}

=item C<$fs-E<gt>fdopen($fd)>

Returns the underlying file handle opened for the file descriptor passed.

=cut

sub fdopen {
    my ( $self, $fd ) = @_;
    my $entry = $self->{'fds'}->lookup($fd);

    return $entry->{'handle'};
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
