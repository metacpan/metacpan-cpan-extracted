# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Mount;

use strict;
use warnings;

use Filesys::POSIX::Bits;
use Filesys::POSIX::Module ();
use Filesys::POSIX::Path   ();

use Filesys::POSIX::Error qw(throw);

use Carp qw(confess);

my @METHODS = qw(mount unmount statfs fstatfs mountlist);

Filesys::POSIX::Module->export_methods( __PACKAGE__, @METHODS );

=head1 NAME

Filesys::POSIX::Mount - Exposes VFS mounting functionality to L<Filesys::POSIX>

=head1 DESCRIPTION

C<Filesys::POSIX::Mount> is a mixin module imported into the L<Filesys::POSIX>
namespace by said module that provides a frontend to the internal VFS.  Rather
than dealing in terms of mount point vnodes as L<Filesys::POSIX::VFS> does, the
system calls provided in this module deal in terms of pathnames.

=head1 SYSTEM CALLS

=over

=item C<$fs-E<gt>mount($dev, $path, %opts)>

Attach the filesystem device, C<$dev>, to the directory inode specified by
C<$path>.  The C<%opts> hash can be used to pass mount options to the
initialization routines for the device object to be mounted; these options are
passed to the C<$dev-E<gt>init()> routine that said filesystem device
implements.

The filesystem mount record is kept in an ordered list by the VFS, and can be
retrieved later using the C<$fs-E<gt>statfs>, or C<$fs-E<gt>mountlist> system
calls.

=cut

sub mount {
    my ( $self, $dev, $path, %opts ) = @_;
    my $mountpoint = $self->stat($path);
    my $realpath   = $self->_find_inode_path($mountpoint);

    $opts{'fs'} ||= $self;

    $dev->init(%opts);

    $self->{'vfs'}->mount( $dev, $realpath, $mountpoint, %opts );
}

=item C<$fs-E<gt>unmount($path)>

Attempts to unmount a filesystem mounted at the directory pointed to by
C<$path>, performing a number of sanity checks to ensure the safety of the
current operation.  The following checks are made:

=over

=item The directory inode is retrieved using C<$fs-E<gt>stat>.

=item Using C<Filesys::POSIX::VFS-E<gt>statfs>, with the directory inode passed,
the VFS is queried to determine if the location given has a filesystem mounted
at all.  If so, the mount record is kept for reference for the next series of
checks.

=item The file descriptor table is scanned for open files whose inodes exist on
the device found for the mount record queried in the previous step by the VFS.
An EBUSY exception is thrown when matching file descriptors are found.

=item The current working directory is checked to ensure it is not a reference
to a directory inode associated with the mounted device.  An EBUSY exception is
thrown if the current directory is on the same device that is to be unmounted.

=back

=cut

sub unmount {
    my ( $self, $path ) = @_;
    my $mountpoint = $self->stat($path);
    my $mount = $self->{'vfs'}->statfs( $mountpoint, 'exact' => 1 );

    #
    # First, check for open file descriptors held on the desired device.
    #
    foreach ( $self->{'fds'}->list ) {
        my $inode = $self->{'fds'}->lookup($_)->{'inode'};

        throw &Errno::EBUSY if $mount->{'dev'} eq $inode->{'dev'};
    }

    #
    # Next, check to see if the current working directory's device inode
    # is the same device as the one being requested for unmounting.
    #
    throw &Errno::EBUSY if $mount->{'dev'} eq $self->{'cwd'}->{'dev'};

    $self->{'vfs'}->unmount($mount);
}

=item C<$fs-E<gt>statfs($path)>

Returns the mount record for the device associated with the inode specified by
$path.  The inode is found using C<$fs-E<gt>stat>, then queried for by
C<Filesys::POSIX::VFS-E<gt>statfs>.

=cut

sub statfs {
    my ( $self, $path ) = @_;
    my $inode = $self->stat($path);

    return $self->{'vfs'}->statfs($inode);
}

=item C<$fs-E<gt>fstatfs($fd)>

Returns the mount record for the device associated with the inode referenced by
the open file descriptor, C<$fd>.  The inode is found using C<$fs-E<gt>fstat>,
then queried for by C<Filesys::POSIX::VFS-E<gt>statfs>.

=cut

sub fstatfs {
    my ( $self, $fd ) = @_;
    my $inode = $self->fstat($fd);

    return $self->{'vfs'}->statfs($inode);
}

=item C<$fs-E<gt>mountlist>

Returns a list of records for each filesystem currently mounted, in the order
in which they were mounted.

=cut

sub mountlist {
    shift->{'vfs'}->mountlist;
}

=back

=head1 ANATOMY OF A MOUNT RECORD

Mount records are created internally by C<Filesys::POSIX::VFS-E<gt>mount>, and
are stored as anonymous HASHes.  They contain the following attributes:

=over

=item C<mountpoint>

Reference to the directory inode (or vnode in the case of multiple filesystems
mounted in the same logical location) the filesystem is mounted to.

=item C<root>

Reference to the mounted filesystem's root directory inode.  This is never a
vnode.

=item C<special>

The value of the C<special> flag specified in a call to C<$fs-E<gt>mount>.  When
no value is specified, the value stored is equal to C<ref $dev>.

=item C<dev>

A reference to the filesystem device object that was mounted by
C<$fs-E<gt>mount>.

=item C<type>

A lowercase string formed by chopping all but the last item in a Perl fully
qualified package name corresponding to the type of the device mounted.  For
instance, an instance of L<Filesys::POSIX::Mem> mounted will result in a value
of C<'mem'>.

=item C<path>

The true, original, and sanitized path of the mount point specified by
C<$fs-E<gt>mount>.

=item C<vnode>

A VFS inode created by C<Filesys::POSIX::VFS::Inode-E<gt>new>, containing most
attributes of the mounted device's root inode, but with a parent pointing to
the mount point inode's parent.

=item C<flags>

A copy of the options passed to C<$fs-E<gt>mount>, minus the C<special> option.

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
