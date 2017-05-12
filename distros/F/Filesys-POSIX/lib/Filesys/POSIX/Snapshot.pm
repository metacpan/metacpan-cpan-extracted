# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Snapshot;

use strict;
use warnings;

use Filesys::POSIX::Bits;
use Filesys::POSIX::Path            ();
use Filesys::POSIX::Snapshot::Inode ();

use Filesys::POSIX::Error qw(throw);

=head1 NAME

Filesys::POSIX::Snapshot - Create and operate on filesystem snapshots

=head1 SYNOPSIS

    use Filesys::POSIX::Snapshot;

    ...

    $fs->mkpath('/snapshots/1');

    $fs->mount(Filesys::POSIX::Snapshot->new, '/snapshots/1',
        'path' => '/'
    );

=head1 DESCRIPTION

This module implements a sort of snapshotting, or copy-on-write, mechanism that
allows for the manipulation of any part of a filesystem in an isolated manner
that does not affect the original data.

Depending on mount arguments, directory hierarchies are copied into memory as
they are encountered, or are copied entirely into memory.  Regular files are
duplicated only when they are opened with C<$O_WRONLY> or C<$O_RDWR> flags.

=head1 MOUNT ARGUMENTS

The following mount arguments are accepted by L<Filesys::POSIX::Snapshot>.

The following value is mandatory:

=over

=item C<path>

The path within the current virtual filesystem which the snapshot will be based
on.

=back

The following value is not mandatory:

=over

=item C<immediate_dir_copy>

When set to a true value, the entire hierarchy of directory listings and inodes
will be duplicated into memory from its source specified in the C<path> value.

=back

=head1 CREATING A NEW FILESYSTEM

=over

=item C<Filesys::POSIX::Snapshot-E<gt>new>

Create a new, uninitialized snapshot filesystem object.

=back

=cut

sub new {
    return bless {}, shift;
}

=head1 INITIALIZATION

=over

=item C<$fs-E<gt>init(%data)>

Initializes the new snapshot filesystem.  A reference to the C<%data> structure
will be retained in the filesystem object.

Exceptions will be thrown for the following:

=over

=item * EINVAL (Invalid argument)

No C<L<path>> value was specified.

=item * ENOENT (No such file or directory)

The path specified in mount argument C<L<path>> does not exist within the
current virtual filesystem.

=item * ENOTDIR (Not a directory)

The path specified in mount argument C<L<path>> is not a directory.

=back

=back

=cut

sub init {
    my ( $self, %data ) = @_;

    my $path = $data{'path'} or throw &Errno::EINVAL;
    my $inode = $data{'fs'}->stat($path);

    throw &Errno::ENOTDIR unless $inode->dir;

    $self->{'flags'} = \%data;

    my $root = Filesys::POSIX::Snapshot::Inode->from_inode( $inode, 'dev' => $self );

    $self->{'root'}   = $root;
    $root->{'parent'} = $root;

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
