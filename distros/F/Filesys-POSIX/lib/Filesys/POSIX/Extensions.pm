# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Extensions;

use strict;
use warnings;

use Filesys::POSIX::Bits;
use Filesys::POSIX::Module          ();
use Filesys::POSIX::Path            ();
use Filesys::POSIX::Real::Inode     ();
use Filesys::POSIX::Real::Directory ();

use Filesys::POSIX::Error qw(throw);

my @METHODS = qw(attach map alias detach replace);

Filesys::POSIX::Module->export_methods( __PACKAGE__, @METHODS );

=head1 NAME

Filesys::POSIX::Extensions - Provides features not found in a POSIX environment
environment

=head1 SYNOPSIS

    use Filesys::POSIX::Extensions;

=head1 DESCRIPTION

This module of extensions provides system calls that would be considered
nonstandard in a POSIX environment, but nonetheless provide their functionality
with standard filesystem semantics.  These extensions provide novel means of
performing efficient filesystem manipulation, allowing the developer to attach
arbitrary inodes in specified locations, detach, replace, and perform cross-
device symlinks.

=head1 SYSTEM CALLS

=over

=item C<$fs-E<gt>attach($inode, $dest)>

Attaches the given inode object to the filesystem in the specified location.
Exceptions will be thrown for the following:

=over

=item * EEXIST (File exists)

An inode at the destination path already exists.

=back

Upon success, the inode provided will be returned to the caller.

=cut

sub attach {
    my ( $self, $inode, $dest ) = @_;
    my $hier      = Filesys::POSIX::Path->new($dest);
    my $name      = $hier->basename;
    my $parent    = $self->stat( $hier->dirname );
    my $directory = $parent->directory;

    $! = 0;

    throw &Errno::EEXIST if $directory->exists($name);

    $directory->set( $name, $inode );

    return $inode;
}

=item C<$fs-E<gt>map($real_src, $dest)>

Manifests a L<Filesys::POSIX::Real::Inode> object corresponding to the actual
inode from the underlying filesystem whose path is specified by C<$real_src>,
and attaches it to the virtual filesystem in the location specified by C<$dest>.

Any inodes mapped from the real filesystem into a virtual filesystem have the
C<sticky> update flag set, meaning, only certain operations made on the in-memory
inode affect the real inode.  See L<Filesys::POSIX::Real> for further details.

Exceptions will be thrown in the following conditions:

=over

=item * EEXIST (File exists)

An inode at the destination path already exists.

=back

Other exceptions may be thrown, based on the availability and permissions of
the actual inode referred to by C<$real_src>.

Upon success, a reference to the C<Filesys::POSIX::Real::Inode> object created
will be returned to the caller.

=cut

sub map {
    my ( $self, $real_src, $dest ) = @_;
    my $hier      = Filesys::POSIX::Path->new($dest);
    my $name      = $hier->basename;
    my $parent    = $self->stat( $hier->dirname );
    my $directory = $parent->directory;

    $! = 0;

    throw &Errno::EEXIST if $directory->exists($name);

    my $inode = Filesys::POSIX::Real::Inode->from_disk(
        $real_src,
        'dev'    => $parent->{'dev'},
        'sticky' => 1,
        'parent' => $parent
    );

    return $directory->set( $name, $inode );
}

=item C<$fs-E<gt>alias($src, $dest)>

Very similar to C<$fs-E<gt>link>, however this system call allows inode aliases
to be made across filesystem mount points.  It is also possible to alias
directories, unlike C<$fs-E<gt>link>.  Exceptions will be thrown for the following:

=over

=item * EEXIST (File exists)

An inode at the destination path was found.

=back

Upon success, a reference to the source inode will be returned to the caller.

=cut

sub alias {
    my ( $self, $src, $dest ) = @_;
    my $hier      = Filesys::POSIX::Path->new($dest);
    my $name      = $hier->basename;
    my $inode     = $self->lstat($src);
    my $parent    = $self->stat( $hier->dirname );
    my $directory = $parent->directory;

    $! = 0;

    throw &Errno::EEXIST if $directory->exists($name);

    return $directory->set( $name, $inode );
}

=item C<$fs-E<gt>detach($path)>

Detaches the inode of the given path from the virtual filesystem.  This call is
similar to C<$fs-E<gt>unlink>, except a different underlying, filesystem-
dependent method is used to detach an inode from the path's parent directory in
the case of C<$fs-E<gt>unlink>.  Both directories and non-directories alike can
be detached from any point in the filesystem using this call; directories do not
have to be empty.

Given a directory object, the C<$directory-E<gt>detach> call is used, which only
removes the inode from the directory itself; whereas C<$directory-E<gt>delete>,
as used by C<$fs-E<gt>unlink>, would perform an L<unlink()|perlfunc/unlink> at
the system level in the case of a L<Filesys::POSIX::Real::Directory>. object.
This way, it is possible to only perform logical deletes of inodes, without
affecting the underlying filesystem when managing inodes brought into existence
using other system calls in this extensions module.

Exceptions are thrown for the following:

=over

=item * ENOENT (No such file or directory)

Thrown when the parent directory of the item in $path does not contain an item
named in the final component of the path.

=back

Upon success, a reference to the inode detached from the filesystem will be
returned.

=cut

sub detach {
    my ( $self, $path ) = @_;
    my $hier      = Filesys::POSIX::Path->new($path);
    my $name      = $hier->basename;
    my $parent    = $self->stat( $hier->dirname );
    my $directory = $parent->directory;

    $! = 0;

    throw &Errno::ENOENT unless $directory->exists($name);

    return $directory->detach($name);
}

=item C<$fs-E<gt>replace($path, $inode)>

Replaces an existent inode specified by C<$path> with the inode object passed in
the C<$inode> argument.  The existing and specified inodes can be of any type.

Exceptions will be thrown for the following:

=over

=item * ENOENT (No such file or directory)

No inode was found at the path specified.

=back

Upon success, a reference to the inode passed to this method will be returned
to the caller.

=cut

sub replace {
    my ( $self, $path, $inode ) = @_;
    my $hier      = Filesys::POSIX::Path->new($path);
    my $name      = $hier->basename;
    my $parent    = $self->stat( $hier->dirname );
    my $directory = $parent->directory;

    $! = 0;

    throw &Errno::ENOENT unless $directory->exists($name);

    $directory->detach($name);

    return $directory->set( $name, $inode );
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
