# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Directory;

use strict;
use warnings;

use Carp qw(confess);

=head1 NAME

Filesys::POSIX::Directory - Base class for implementing directory structures

=head1 DESCRIPTION

Filesys::POSIX::Directory is a common interface used to implement classes that
act like directories, and should be able to be accessed randomly or in an
iterative fashion.

Classes which wish to implement the interface documented herein should provide
implementations for ALL methods listed in this document, in the manner in which
they are described within this document.

=head1 RANDOM ACCESS

=over

=item C<$directory-E<gt>get($name)>

If the current directory contains an item named for C<$name>, return the
corresponding inode.  Otherwise, an C<undef> is returned.

=cut

sub get {
    confess('Not implemented');
}

=item C<$directory-E<gt>set($name, $inode)>

Store a reference to C<$inode> in the current directory, named after the member
label C<$name>.  If an item already exists for C<$name>, then it will be
replaced by C<$inode>.

=cut

sub set {
    confess('Not implemented');
}

=item C<$directory-E<gt>exists($name)>

Returns true if a member called C<$name> exists in the current directory.
Returns false if no such member inode is listed.

=cut

sub exists {
    confess('Not implemented');
}

=item C<$directory-E<gt>detach($name)>

Drop any references to a member called C<$name> in the current directory.  No
side effects outside of the directory object instance shall occur.

=cut

sub detach {
    confess('Not implemented');
}

=item C<$directory-E<gt>delete($name)>

Drop any references to a member called C<$name> in the current directory.  Side
effects to other system resources referenced by this directory member may
potentially occur, depending on the specific directory implementation.

=cut

sub delete {
    confess('Not implemented');
}

=back

=head1 LIST ACCESS

=over

=item C<$directory-E<gt>list()>

Return a list of all items in the current directory, including C<.> and C<..>.

=cut

sub list {
    confess('Not implemented');
}

=item C<$directory-E<gt>count()>

Return the number of all items in the current directory, including C<.> and
C<..>.

=cut

sub count {
    confess('Not implemented');
}

=item C<$directory-E<gt>empty()>

Returns true if the directory only contains the C<.> and C<..> entries.

=cut

sub empty {
    my ($self) = @_;

    return $self->count == 2;
}

=back

=head1 ITERATIVE ACCESS

=over

=item C<$directory-E<gt>open()>

Prepare the current directory object for iterative reading access.

=cut

sub open {
    confess('Not implemented');
}

=item C<$directory-E<gt>rewind()>

Rewind the current directory object to the beginning of the directory list when
being accessed iteratively.

=cut

sub rewind {
    confess('Not implemented');
}

=item C<$directory-E<gt>read()>

Read and return a single item from the directory, advancing the pointer to the
next item to be read, if any.  A list containing both the name of the object,
and the inode it references, are returned.

=cut

sub read {
    confess('Not implemented');
}

=item C<$directory-E<gt>close()>

Close the current directory for iterative access.

=cut

sub close {
    confess('Not implemented');
}

=item C<$directory-E<gt>rename_member()>

Rename an item from one Filesys::POSIX::Directory so that it becomes
a member of another Filesys::POSIX::Directory and/or changes name.

=cut

sub rename_member {
    my ( $self, $inode, $old_dir, $old_name, $new_name ) = @_;
    $old_dir->detach($old_name);
    $self->set( $new_name, $inode );
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
