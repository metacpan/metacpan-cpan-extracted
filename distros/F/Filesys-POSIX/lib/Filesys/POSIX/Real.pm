# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Real;

use strict;
use warnings;

use Filesys::POSIX::Bits;
use Filesys::POSIX::Path            ();
use Filesys::POSIX::Real::Inode     ();
use Filesys::POSIX::Real::Directory ();
use Filesys::POSIX::Error qw(throw);

=head1 NAME

Filesys::POSIX::Real - Portal to actual underlying filesystem

=head1 SYNOPSIS

    use Filesys::POSIX;
    use Filesys::POSIX::Real;

    my $fs = Filesys::POSIX->new(Filesys::POSIX::Real->new,
        'path'    => '/home/foo/test',
        'noatime' => 1
    );

=head1 DESCRIPTION

This module implements the filesystem device type which provides a portal to
the actual system's underlying filesystem.

=head1 MOUNT OPTIONS

The following value is mandatory:

=over

=item C<path>

The path, in the real filesystem, upon which the new filesystem to be mounted
will be based.

=back

The following value is not mandatory:

=over

=item C<sticky>

When set to a value evaluating to true, any updates to certain attributes of any
inode brought to life by this module are not committed to disk.  When this flag
is used, the following calls only affect the inode in memory, but not on disk:

=over

=item C<$fs-E<gt>chmod>

=item C<$fs-E<gt>chown>

=item C<$fs-E<gt>symlink>

=back

Furthermore, only the following attributes are synced from disk onto their
corresponding memory inodes:

=over

=item C<size>

=item C<atime>

=item C<mtime>

=item C<ctime>

=back

=back

=head1 CREATING A NEW FILESYSTEM

=over

=item C<Filesys::POSIX::Real-E<gt>new>

Create a new, uninitialized filesystem.

=back

=cut

sub new {
    return bless {}, shift;
}

=head1 INITIALIAZATION

=over

=item C<$fs-E<gt>init(%data)>

Initializes the new filesystem.  A reference to the C<%data> argument is saved
in the filesystem object.

Exceptions will be thrown for the following:

=over

=item * EINVAL (Invalid argument)

No value was specified for C<$data{'path'}>.

=item * ENOTDIR (Not a directory)

The path specified in C<$data{'path'}> on the real filesystem does not
correspond to an actual directory.

=back

=back

=cut

sub init {
    my ( $self, %data ) = @_;

    my $path = $data{'path'} or throw &Errno::EINVAL;

    my $root = Filesys::POSIX::Real::Inode->from_disk( $path, 'dev' => $self );

    throw &Errno::ENOTDIR unless $root->dir;

    $self->{'flags'} = \%data;
    $self->{'path'}  = Filesys::POSIX::Path->full($path);
    $self->{'root'}  = $root;

    return $self;
}

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
