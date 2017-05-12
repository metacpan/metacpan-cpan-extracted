# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Mem;

use strict;
use warnings;

use Filesys::POSIX::Bits;
use Filesys::POSIX::Mem::Inode ();

=head1 NAME

Filesys::POSIX::Mem - Filesystem whose logical structure resides solely in
program memory

=head1 DESCRIPTION

C<Filesys::POSIX::Mem> provides a filesystem whose structure and, to a large
extent, contents of regular files, exist solely in program memory as Perl data
structures and string buffers.  Regular file data up to a certain size can exist
entirely in memory; files exceeding that size are dumped to temporary files
backed by L<File::Temp>.

=head1 MOUNT OPTIONS

=over

=item C<bucket_dir>

Allows one to specify the directory in which temporary bucket files which back
regular file data are to be created and kept.

=item C<bucket_max>

Specifies the maximum size, in bytes, of a regular file as it is kept in memory
before being flushed to a bucket file in disk.  The default value is, as per
L<Filesys::POSIX::Mem::Inode>, C<16384> bytes.

=back

=cut

sub new {
    my ($class) = @_;
    my $fs = bless {}, $class;

    $fs->{'root'} = Filesys::POSIX::Mem::Inode->new(
        'mode' => $S_IFDIR | 0755,
        'dev'  => $fs
    );

    return $fs;
}

sub init {
    my ( $self, %flags ) = @_;

    $self->{'flags'} = \%flags;

    return $self;
}

=head1 SEE ALSO

=over

=item L<Filesys::POSIX::Mem::Inode>

C<Filesys::POSIX::Mem> implementation of the inode construct.

=item L<Filesys::POSIX::Mem::Bucket>

C<Filesys::POSIX::Mem> implementation of file handles associated with regular
file data.

=item L<Filesys::POSIX::Mem::Directory>

C<Filesys::POSIX::Mem> implementation of directory iterable directory structures
as defined by the L<Filesys::POSIX::Directory> interface.

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
