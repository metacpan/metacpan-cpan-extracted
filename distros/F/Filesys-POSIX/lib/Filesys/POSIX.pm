# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX;

use strict;
use warnings;

use Filesys::POSIX::Mem     ();
use Filesys::POSIX::FdTable ();
use Filesys::POSIX::Path    ();
use Filesys::POSIX::VFS     ();
use Filesys::POSIX::Bits;

use Filesys::POSIX::IO       ();
use Filesys::POSIX::Mount    ();
use Filesys::POSIX::Userland ();

use Filesys::POSIX::Error qw(throw);

use Carp qw(confess);

our $VERSION = '0.9.19';

=head1 NAME

Filesys::POSIX - Provide POSIX-like filesystem semantics in pure Perl

=head1 SYNOPSIS

    use Filesys::POSIX
    use Filesys::POSIX::Mem;

    my $fs = Filesys::POSIX->new(Filesys::POSIX::Mem->new,
        'noatime' => 1
    );

    $fs->umask(0700);
    $fs->mkdir('foo');

    my $fd = $fs->open('/foo/bar', $O_CREAT | $O_WRONLY);
    my $inode = $fs->fstat($fd);
    $fs->printf("I have mode 0%o\n", $inode->{'mode'});
    $fs->close($fd);

=head1 DESCRIPTION

Filesys::POSIX provides a fairly complete suite of tools comprising the
semantics of a POSIX filesystem, with path resolution, mount points, inodes,
a VFS, and some common utilities found in the userland.  Some features not
found in a normal POSIX environment include the ability to perform cross-
mountpoint hard links (aliasing), mapping portions of the real filesystem into
an instance of a virtual filesystem, and allowing the developer to attach and
replace inodes at arbitrary points with replacements of their own
specification.

Two filesystem types are provided out-of-the-box: A filesystem that lives in
memory completely, and a filesystem that provides a "portal" to any given
portion of the real underlying filesystem.

By and large, the manner in which data is structured is quite similar to a
real kernel filesystem implementation, with some differences: VFS inodes are
not created for EVERY disk inode (only mount points); inodes are not referred
to numerically, but rather by Perl reference; and, directory entries can be
implemented in a device-specific manner, as long as they adhere to the normal
interface specified within.

=head1 INSTANTIATING THE FILESYSTEM ENVIRONMENT

=over

=item C<Filesys::POSIX-E<gt>new($rootfs, %opts)>

Create a new filesystem environment, specifying a reference to an
uninitialized instance of a filesystem type object to be mounted at the root
of the virtual filesystem.  Options passed will be passed to the filesystem
initialization method C<$rootfs-E<gt>init()> in flat hash form, and passed on
again to the VFS, where the options will be stored for later retrieval.

=back

=head1 ERROR HANDLING

Errors are emitted in the form of exceptions thrown by
L<C<Carp::confess()>|Carp/confess>, with full stack traces.  Where possible,
L<C<$!>|perlvar/$!> is set with an appropriate error code from L<Errno>, and a
stringified L<C<$!>|perlvar/$!> is thrown.

=cut

sub new {
    my ( $class, $rootfs, %opts ) = @_;

    confess('No root filesystem specified') unless $rootfs;

    $rootfs->init(%opts);

    my $vfs = Filesys::POSIX::VFS->new->mount( $rootfs, '/', $rootfs->{'root'}, %opts );

    return bless {
        'methods' => {},
        'umask'   => 022,
        'fds'     => Filesys::POSIX::FdTable->new,
        'cwd'     => $rootfs->{'root'},
        'root'    => $rootfs->{'root'},
        'vfs'     => $vfs,
        'cwd'     => $vfs->vnode( $rootfs->{'root'} ),
        'root'    => $vfs->vnode( $rootfs->{'root'} )
    }, $class;
}

=head1 SYSTEM CALLS

=over

=item C<$fs-E<gt>umask()>

=item C<$fs-E<gt>umask($mode)>

When called without an argument, the current umask value is returned.  When a
value is specified, the current umask is modified to that value, and is
returned once set.

=cut

sub umask {
    my ( $self, $umask ) = @_;

    return $self->{'umask'} = $umask if defined $umask;
    return $self->{'umask'};
}

sub _find_inode {
    my ( $self, $path, %opts ) = @_;
    my $hier = Filesys::POSIX::Path->new($path);
    my $dir  = $self->{'cwd'};
    my $inode;

    return $self->{'root'} if $hier->full eq '/';

    while ( $hier->count ) {
        my $item = $hier->shift;

        #
        # We've encountered an absolute path.  Start from the beginning.
        #
        unless (length $item) {
            $dir = $self->{'root'};
            next;
        }

        #
        # Before we go further, we need to resolve the current directory for
        # a possible VFS inode in the event of a mountpoint or filesystem root.
        #
        $dir = $self->{'vfs'}->vnode($dir);

        unless ( $dir->{'dev'}->{'flags'}->{'noatime'} ) {
            $dir->{'atime'} = time;
        }

        #
        # From this point, deal with the directory in terms of a directory entry.
        #
        my $directory = $dir->directory;

        if ( $item eq '.' ) {
            $inode = $dir;
        }
        elsif ( $item eq '..' ) {
            my $vnode = $self->{'vfs'}->vnode($dir);
            $inode =
                $vnode->{'parent'}
              ? $vnode->{'parent'}
              : $self->{'vfs'}->vnode( $directory->get('..') );
        }
        else {
            $inode = $self->{'vfs'}->vnode( $directory->get($item) );
        }

        $! = 0;

        throw &Errno::ENOENT unless $inode;

        if ( $inode->link ) {
            $hier = $hier->concat( $inode->readlink )
              if $opts{'resolve_symlinks'} || $hier->count;
        }
        else {
            $dir = $inode;
        }
    }

    return $inode;
}

=item C<$fs-E<gt>stat($path)>

Resolve the given path for an inode in the filesystem.  If the inode found is
a symlink, the path of that symlink will be resolved in turn until the desired
inode is located.

Paths will be resolved relative to the current working directory when not
prefixed with a slash ('C</>'), and will be resolved relative to the root
directory when prefixed with a slash ('C</>').

=cut

sub stat {
    my ( $self, $path ) = @_;
    return $self->_find_inode( $path, 'resolve_symlinks' => 1 );
}

=item C<$fs-E<gt>lstat($path)>

Resolve the given path for an inode in the filesystem.  Unlinke
C<$fs-E<gt>stat()>, the inode found will be returned literally in the case of a
symlink.

=cut

sub lstat {
    my ( $self, $path ) = @_;
    return $self->_find_inode($path);
}

=item C<$fs-E<gt>fstat($fd)>

Return the inode corresponding to the open file descriptor passed.  An
exception will be thrown by the file descriptor lookup module if the file
descriptor passed does not correspond to an open file.

=cut

sub fstat {
    my ( $self, $fd ) = @_;
    return $self->{'fds'}->lookup($fd)->{'inode'};
}

=item C<$fs-E<gt>chdir($path)>

Change the current working directory to the path specified.  An
C<$fs-E<gt>stat()> call will be used internally to lookup the inode for that
path; an ENOTDIR will be thrown unless the inode found is a directory.  The
internal current working directory pointer will be updated with the directory
inode found; this same inode will also be returned.

=cut

sub chdir {
    my ( $self, $path ) = @_;
    my $inode = $self->stat($path);

    $! = 0;

    throw &Errno::ENOTDIR unless $inode->dir;

    return $self->{'cwd'} = $inode;
}

=item C<$fs-E<gt>fchdir($fd)>

When passed a file descriptor for a directory, update the internal pointer to
the current working directory to that directory resolved from the file
descriptor table, and return the same directory inode.  If the inode is not a
directory, an ENOTDIR will be thrown.

=cut

sub fchdir {
    my ( $self, $fd ) = @_;
    my $inode = $self->fstat($fd);

    $! = 0;

    throw &Errno::ENOTDIR unless $inode->dir;

    return $self->{'cwd'} = $inode;
}

=item C<$fs-E<gt>chown($path, $uid, $gid)>

Using C<$fs-E<gt>stat()> to locate the inode of the path specified, update that
inode object's 'uid' and 'gid' fields with the values specified.  The inode of
the file modified will be returned.

=cut

sub chown {
    my ( $self, $path, $uid, $gid ) = @_;
    my $inode = $self->stat($path);

    $inode->chown( $uid, $gid );

    return $inode;
}

=item C<$fs-E<gt>fchown($fd, $uid, $gid)>

Using C<$fs-E<gt>fstat()> to locate the inode of the file descriptor specified,
update that inode object's 'uid' and 'gid' fields with the values specified.  A
reference to the affected inode will be returned.

=cut

sub fchown {
    my ( $self, $fd, $uid, $gid ) = @_;
    my $inode = $self->fstat($fd);

    $inode->chown( $uid, $gid );

    return $inode;
}

=item C<$fs-E<gt>chmod($path, $mode)>

Using C<$fs-E<gt>stat()> to locate the inode of the path specified, update that
inode object's 'mode' field with the value specified.  A reference to the
affected inode will be returned.

=cut

sub chmod {
    my ( $self, $path, $mode ) = @_;
    my $inode = $self->stat($path);

    $inode->chmod($mode);

    return $inode;
}

=item C<$fs-E<gt>fchmod($fd, $mode)>

Using C<$fs-E<gt>fstat()> to locate the inode of the file descriptor specified,
update that inode object's 'mode' field with the value specified.  A reference
to that inode will be returned.

=cut

sub fchmod {
    my ( $self, $fd, $mode ) = @_;
    my $inode = $self->fstat($fd);

    $inode->chmod($mode);

    return $inode;
}

=item C<$fs-E<gt>mkdir($path)>

=item C<$fs-E<gt>mkdir($path, $mode)>

Create a new directory at the path specified, applying the permissions field in
the mode value specified.  If no mode is specified, the default permissions of
I<0777> will be modified by the current umask value.  An ENOTDIR exception will
be thrown in case the intended parent of the directory to be created is not
actually a directory itself.

A reference to the newly-created directory inode will be returned.

=cut

sub mkdir {
    my ( $self, $path, $mode ) = @_;
    my $hier   = Filesys::POSIX::Path->new($path);
    my $name   = $hier->basename;
    my $parent = $self->stat( $hier->dirname );
    my $perm   = $mode ? $mode & ( $S_IPERM | $S_IPROT ) : $S_IPERM ^ $self->{'umask'};

    return $parent->child( $name, $perm | $S_IFDIR );
}

=item C<$fs-E<gt>link($src, $dest)>

Using C<$fs-E<gt>stat()> to resolve the path of the link source, and the parent
of the link destination, C<$fs-E<gt>link()> place a reference to the source
inode in the location specified by the destination.

If a destination inode already exists, it will only be able to be replaced by
the source if both are either directories or non-directories.  If the source
and destination are both directories, the destination will only be replaced if
the directory entry for the destination is empty.

Links traversing filesystem mount points are not allowed.  This functionality
is provided in the C<alias()> call provided by the L<Filesys::POSIX::Extensions>
module.  Upon success, a reference to the inode for which a new link is to be
created will be returned.

Exceptions thrown:

=over

=item * EXDEV (Cross-device link)

The inode resolved for the link source is not associated with the same device
as the inode of the destination's parent directory.

=item * EISDIR (Is a directory)

Thrown if the source inode is a directory.  Hard links can only be made for
non-directory inodes.

=item * EEXIST (File exists)

Thrown if an entry at the destination path already exists.

=back

=cut

sub link {
    my ( $self, $src, $dest ) = @_;
    my $hier      = Filesys::POSIX::Path->new($dest);
    my $name      = $hier->basename;
    my $inode     = $self->stat($src);
    my $parent    = $self->stat( $hier->dirname );
    my $directory = $parent->directory;

    $! = 0;

    throw &Errno::EXDEV unless $inode->{'dev'} == $parent->{'dev'};
    throw &Errno::EISDIR if $inode->dir;
    throw &Errno::EEXIST if $directory->exists($name);

    $directory->set( $name, $inode );

    return $inode;
}

=item C<$fs-E<gt>symlink($old, $new)>

The path in the first argument specified, C<$old>, is cleaned up using
C<Filesys::POSIX::Path-E<gt>full>, and stored in a new symlink inode created
in the location specified by C<$new>.  An EEXIST exception will be thrown if an
inode at the path indicated by C<$new> exists.  A reference to the newly-created
symlink inode will be returned.

=cut

sub symlink {
    my ( $self, $old, $new ) = @_;
    my $perms  = $S_IPERM ^ $self->{'umask'};
    my $hier   = Filesys::POSIX::Path->new($new);
    my $name   = $hier->basename;
    my $parent = $self->stat( $hier->dirname );

    return $parent->child( $name, $S_IFLNK | $perms )->symlink( Filesys::POSIX::Path->full($old) );
}

=item C<$fs-E<gt>readlink($path)>

Using C<$fs-E<gt>lstat()> to resolve the given path for an inode, the symlink
destination path associated with the inode is returned as a string.  An EINVAL
exception is thrown unless the inode found is indeed a symlink.

=cut

sub readlink {
    my ( $self, $path ) = @_;
    my $inode = $self->lstat($path);

    $! = 0;

    throw &Errno::EINVAL unless $inode->link;

    return $inode->readlink;
}

=item C<$fs-E<gt>unlink($path)>

Using C<$fs-E<gt>lstat()> to resolve the given path for an inode specified,
said inode will be removed from its parent directory entry.  The following
exceptions will be thrown in the event of certain errors:

=over

=item * ENOENT (No such file or directory)

No entry was found in the path's parent directory for the item specified in the
path.

=item * EISDIR (Is a directory)

C<$fs-E<gt>unlink()> was called with a directory specified.
C<$fs-E<gt>rmdir()> must be used instead for removing directory inodes.

=back

Upon success, a reference to the inode removed from its parent directory will
be returned.

=cut

sub unlink {
    my ( $self, $path ) = @_;
    my $hier      = Filesys::POSIX::Path->new($path);
    my $name      = $hier->basename;
    my $parent    = $self->lstat( $hier->dirname );
    my $directory = $parent->directory;
    my $inode     = $directory->get($name);

    $! = 0;

    throw &Errno::ENOENT unless $inode;
    throw &Errno::EISDIR if $inode->dir;

    $directory->delete($name);

    return $inode;
}

=item C<$fs-E<gt>rename($old, $new)>

Relocate the item specified by the C<$old> argument to the new path specified by
$new.

Using C<$fs-E<gt>lstat>, the inode for the old pathname is resolved;
C<$fs-E<gt>stat> is then used to resolve the path of the parent directory of
the argument specified in C<$new>.

If an inode exists at the path specified by C<$new>, it will be replaced by
C<$old> in the following circumstances:

=over

=item Both the source C<$old> and destination C<$new> are non-directory inodes.

=item Both the source C<$old> and destination C<$new> are directory inodes, and
the destination is empty.

=back

The following exceptions are thrown for error conditions:

=over

=item * EPERM (Operation not permitted)

Currently, C<$fs-E<gt>rename()> cannot operate if the inode at the old location
is an inode associated with a Filesys::POSIX::Real filesystem type.

=item * EXDEV (Cross-device link)

The inode at the old path does not exist on the same filesystem device as the
inode of the parent directory specified in the new path.

=item * ENOTDIR (Not a directory)

The old inode is a directory, but an existing inode found in the new path
specified, is not.

=item * EISDIR (Is a directory)

The old inode is not a directory, but an existing inode found in the new path
specified, is.

=item * ENOTEMPTY (Directory not empty)

Both the old and new paths correspond to a directory, but the new path is not
of an empty directory.

=back

Upon success, a reference to the inode to be renamed will be returned.

=cut

sub rename {
    my ( $self, $old, $new ) = @_;

    my $inode = $self->lstat($old);

    my $old_hier   = Filesys::POSIX::Path->new($old);
    my $old_name   = $old_hier->basename;
    my $old_parent = $self->stat( $old_hier->dirname );
    my $old_dir    = $old_parent->directory;

    my $new_hier   = Filesys::POSIX::Path->new($new);
    my $new_name   = $new_hier->basename;
    my $new_parent = $self->stat( $new_hier->dirname );
    my $new_dir    = $new_parent->directory;

    $! = 0;

    throw &Errno::EXDEV unless $inode->{'dev'} eq $new_parent->{'dev'};

    if ( my $existing = $new_dir->get($new_name) ) {
        if ( $inode->dir ) {
            throw &Errno::ENOTDIR   unless $existing->dir;
            throw &Errno::ENOTEMPTY unless $existing->empty;
        }
        else {
            throw &Errno::EISDIR if $existing->dir;
        }
    }

    $new_dir->rename_member( $inode, $old_dir, $old_name, $new_name );

    return $inode;
}

=item C<$fs-E<gt>rmdir($path)>

Unlinks the directory inode at the specified path.  Exceptions are thrown in
the following conditions:

=over

=item * ENOENT (No such file or directory)

No inode exists by the name specified in the final component of the path in
the parent directory specified in the path.

=item * EBUSY (Device or resource busy)

The directory specified is an active mount point.

=item * ENOTDIR (Not a directory)

The inode found at C<$path> is not a directory.

=item * ENOTEMPTY (Directory not empty)

The directory is not empty.

=back

Upon success, a reference to the inode of the directory to be removed will be
returned.

=cut

sub rmdir {
    my ( $self, $path ) = @_;
    my $hier      = Filesys::POSIX::Path->new($path);
    my $name      = $hier->basename;
    my $parent    = $self->lstat( $hier->dirname );
    my $directory = $parent->directory;
    my $inode     = $directory->get($name);

    $! = 0;

    throw &Errno::ENOENT unless $inode;

    throw &Errno::EBUSY if $self->{'vfs'}->statfs(
        $self->stat($path),
        'exact' => 1, 'silent' => 1
    );

    throw &Errno::ENOTEMPTY unless $inode->empty;

    $directory->delete($name);

    return $inode;
}

=item C<$fs-E<gt>mknod($path, $mode)>

=item C<$fs-E<gt>mknod($path, $mode, $dev)>

Create a new inode at the specified C<$path>, with the inode permissions and
format specified in the C<$mode> argument.  If C<$mode> specifies a C<$S_IFCHR>
or C<$S_IFBLK> value, then the device number specified in C<$dev> will be given
to the new inode.

Code contained within the C<Filesys::POSIX> distribution assumes that the device
identifier shall contain the major and minor numbers in separate 16-bit fields,
in the following manner:

    my $major = ($dev & 0xffff0000) >> 16;
    my $minor =  $dev & 0x0000ffff;

Returns a reference to a L<Filesys::POSIX::Inode> object upon success.

=cut

sub mknod {
    my ( $self, $path, $mode, $dev ) = @_;
    my $hier      = Filesys::POSIX::Path->new($path);
    my $name      = $hier->basename;
    my $parent    = $self->lstat( $hier->dirname );
    my $directory = $parent->directory;

    my $format = $mode & $S_IFMT;
    my $perms  = $mode & $S_IPERM;

    $! = 0;

    throw &Errno::EINVAL unless $format;
    throw &Errno::EEXIST if $directory->exists($name);

    my $inode = $parent->child( $name, $format | $perms );

    if ( $format == $S_IFCHR || $format == $S_IFBLK ) {
        $inode->{'rdev'} = $dev;
    }

    return $inode;
}

=item C<$fs-E<gt>mkfifo($path, $mode)>

Create a new FIFO device at the specified C<$path>, with the permissions listed
in C<$mode>.  Internally, this function is a frontend to
C<Filesys::POSIX-E<gt>mknod>.

Returns a reference to a L<Filesys::POSIX::Inode> object upon success.

=cut

sub mkfifo {
    my ( $self, $path, $mode ) = @_;

    my $format = $S_IFIFO;
    my $perms  = $mode & $S_IPERM;

    return $self->mknod( $path, $format | $perms );
}

=back

=cut

1;

__END__

=head1 EXTENSION MODULES

=over

=item L<Filesys::POSIX::Extensions>

This module provides a variety of functions for performing inode operations in
novel ways that take advantage of the unique characteristics and features of
Filesys::POSIX.  For example, one method is provided that allows a developer to
map a file or directory from the system's underlying, actual filesystem, into
any arbitrary point in the virtual filesystem.

=item L<Filesys::POSIX::Userland::Find>

Provides the ability to perform breadth-first operations on file hierarchies
within an instance of a C<Filesys::POSIX> filesystem, in a subset of the
functionality provided in L<File::Find>.

=item L<Filesys::POSIX::Userland::Tar>

Provides an implementation of the POSIX ustar and certain aspects of the GNU tar
standard.  Currently allows for the creation of tar archives based on
hierarchies within a C<Filesys::POSIX> instance.

=item L<Filesys::POSIX::Userland::Test>

Provides a series of truth tests that can be performed on files and directories
specified by paths.

=back

=head1 UTILITIES

=over

=item L<Filesys::POSIX::Path>

A publicly-accessible interface for the path name string manipulation functions
used by Filesys::POSIX itself.

=back

=head1 INTERFACES

=over

=item L<Filesys::POSIX::Directory>

Lists the requirements for writing modules that act as directory structures.

=item L<Filesys::POSIX::Inode>

Lists the requirements for writing modules that act as inodes.

=item L<Filesys::POSIX::Module>

Provides an interface for loading methods from modules that extend
Filesys::POSIX.

=back

=head1 INTERNALS

=over

=item L<Filesys::POSIX::Bits>

A listing of bitfields and constants used in various places by Filesys::POSIX.

=item L<Filesys::POSIX::FdTable>

The Filesys::POSIX implementation of the file descriptor allocation table.

=item L<Filesys::POSIX::Userland>

Imported by Filesys::POSIX by default.  Provides many POSIX command line
tool-like functions not documented in the current manual page.

=item L<Filesys::POSIX::IO>

Imported by Filesys::POSIX by default.  Provides standard file manipulation
routines as found in a POSIX filesystem.

=item L<Filesys::POSIX::Mount>

Imported by Filesys::POSIX by default.  Provides a frontend to the VFS mount
point management implementation found in L<Filesys::POSIX::VFS>.

=item L<Filesys::POSIX::VFS>

Used by Filesys::POSIX, this module provides an implementation of a filesystem
mount table and VFS inode resolution routines.

=back

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
