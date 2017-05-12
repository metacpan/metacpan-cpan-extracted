# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Userland::Test;

use strict;
use warnings;

use Filesys::POSIX::Bits;
use Filesys::POSIX::Module ();

my @METHODS = qw(
  exists is_file is_dir is_link is_char is_block is_fifo
  is_readable is_writable is_executable
  is_setuid is_setgid
);

Filesys::POSIX::Module->export_methods( __PACKAGE__, @METHODS );

=head1 NAME

Filesys::POSIX::Userland::Test - Inode conditional tests

=head1 SYNOPSIS

    use Filesys::POSIX;
    use Filesys::POSIX::Mem;
    use Filesys::POSIX::Userland::Test;

    my $fs = Filesys::POSIX->new(Filesys::POSIX::Real->new,
        'noatime' => 1
    );

    $fs->touch('foo');
    $fs->is_file('foo'); # returns 1
    $fs->is_dir('foo');  # returns 0

=head1 DESCRIPTION

This runtime addon module provides a series of boolean tests in the vein of
L<test(1)> that allow introspection of the nature of files without explicitly
having to write boilerplate wrappers around C<$fs-E<gt>stat>.

This module exposes the inode-level tests in the L<Filesys::POSIX::Inode> base
class at a higher, file-oriented level.

=head1 TESTS

=over

=item C<$FS-E<gt>exists($path)>

Returns true if an inode indicated by C<$path> exists.

=cut

sub exists {
    my ( $self, $path ) = @_;

    my $inode = eval { $self->stat($path) };

    return 0 unless $inode;
    return 1;
}

=item C<$fs-E<gt>is_file($path)>

Returns true if an inode indicated by C<$path> exists and is a regular file
(C<$S_IFREG>).

=cut

sub is_file {
    my ( $self, $path ) = @_;

    my $inode = eval { $self->stat($path) };

    return 0 unless $inode;
    return 0 unless $inode->file;
    return 1;
}

=item C<$fs-E<gt>is_dir($path)>

Returns true if an inode indicated by C<$path> exists and is a directory
(C<$S_IFDIR>).

=cut

sub is_dir {
    my ( $self, $path ) = @_;

    my $inode = eval { $self->stat($path) };

    return 0 unless $inode;
    return 0 unless $inode->dir;
    return 1;
}

=item C<$fs-E<gt>is_link($path)>

Returns true if an inode indicated by C<$path> exists and is a symlink
(C<$S_IFLNK>).

=cut

sub is_link {
    my ( $self, $path ) = @_;

    my $inode = eval { $self->lstat($path) };

    return 0 unless $inode;
    return 0 unless $inode->link;
    return 1;
}

=item C<$fs-E<gt>is_char($path)>

Returns true if an inode indicated by C<$path> exists and is a character device
(C<$S_IFCHR>).

=cut

sub is_char {
    my ( $self, $path ) = @_;

    my $inode = eval { $self->stat($path) };

    return 0 unless $inode;
    return 0 unless $inode->char;
    return 1;
}

=item C<$fs-E<gt>is_block($path)>

Returns true if an inode indicated by C<$path> exists and is a block device
(C<$S_IFBLK>).

=cut

sub is_block {
    my ( $self, $path ) = @_;

    my $inode = eval { $self->stat($path) };

    return 0 unless $inode;
    return 0 unless $inode->block;
    return 1;
}

=item C<$fs-E<gt>is_fifo($path)>

Returns true if an inode indicated by C<$path> exists and is a FIFO
(C<$S_IFIFO>).

=cut

sub is_fifo {
    my ( $self, $path ) = @_;

    my $inode = eval { $self->stat($path) };

    return 0 unless $inode;
    return 0 unless $inode->fifo;
    return 1;
}

=item C<$fs-E<gt>is_readable($path)>

Returns true if an inode indicated by C<$path> exists and has a readable bit set
in the inode mode permissions field (C<$S_IRUSR | $S_IRGRP | $S_IROTH>).

=cut

sub is_readable {
    my ( $self, $path ) = @_;

    my $inode = eval { $self->stat($path) };

    return 0 unless $inode;
    return 0 unless $inode->readable;
    return 1;
}

=item C<$fs-E<gt>is_writable($path)>

Returns true if an inode indicated by C<$path> exists and has a writable bit set
in the inode mode permissions field (C<$S_IWUSR | $S_IWGRP | $S_IWOTH>).

=cut

sub is_writable {
    my ( $self, $path ) = @_;

    my $inode = eval { $self->stat($path) };

    return 0 unless $inode;
    return 0 unless $inode->writable;
    return 1;
}

=item C<$fs-E<gt>is_executable($path)>

Returns true if an inode indicated by C<$path> exists and has an executable bit
set in the inode mode permissions field (C<$S_IXUSR | $S_IXGRP | $S_IXOTH>).

=cut

sub is_executable {
    my ( $self, $path ) = @_;

    my $inode = eval { $self->stat($path) };

    return 0 unless $inode;
    return 0 unless $inode->executable;
    return 1;
}

=item C<$fs-E<gt>is_setuid($path)>

Returns true if an inode indicated by C<$path> exists and has a setuid bit
set in the inode mode permissions field (C<$S_SUID>).

=cut

sub is_setuid {
    my ( $self, $path ) = @_;

    my $inode = eval { $self->stat($path) };

    return 0 unless $inode;
    return 0 unless $inode->setuid;
    return 1;
}

=item C<$fs-E<gt>is_setgid($path)>

Returns true if an inode indicated by C<$path> exists and has a setgid bit
set in the inode permissions field (C<$S_SGID>).

=cut

sub is_setgid {
    my ( $self, $path ) = @_;

    my $inode = eval { $self->stat($path) };

    return 0 unless $inode;
    return 0 unless $inode->setgid;
    return 1;
}

=back

=cut

=head1 SEE ALSO

=over

=item L<Filesys::POSIX::Inode>

=item L<Filesys::POSIX::Bits>

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
