# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Bits;

use strict;
use warnings;

BEGIN {
    use Exporter ();
    use vars qw(@ISA @EXPORT);

    our @ISA = qw(Exporter);

    our @EXPORT = qw(
      $O_RDONLY $O_WRONLY $O_RDWR $O_NONBLOCK $O_APPEND $O_CREAT $O_TRUNC
      $O_EXCL $O_SHLOCK $O_EXLOCK $O_NOFOLLOW $O_EVTONLY $S_IFMT
      $S_IFIFO $S_IFCHR $S_IFDIR $S_IFBLK $S_IFREG $S_IFLNK $S_IFSOCK
      $S_IFWHT $S_IPROT $S_ISUID $S_ISGID $S_ISVTX $S_IPERM $S_IRWXU
      $S_IRUSR $S_IWUSR $S_IXUSR $S_IRWXG $S_IRGRP $S_IWGRP $S_IXGRP
      $S_IRWXO $S_IROTH $S_IWOTH $S_IXOTH $S_IRW $S_IR $S_IW $S_IX

      $SEEK_SET $SEEK_CUR $SEEK_END
    );
}

=head1 NAME

Filesys::POSIX::Bits - Bitfield and constant definitions for file modes and
system call flags

=head1 DESCRIPTION

This file contains all the constant definitions for the system call flags and
inode mode bitfields and values.  The following system calls use these values:

=over

=item C<Filesys::POSIX-E<gt>open>

Uses both flag and mode specifiers for determining permissions, file open mode,
and inode format.

=item C<Filesys::POSIX::IO::Handle-E<gt>seek>

Uses C<$SEEK_SET>, C<$SEEK_CUR>, and C<$SEEK_END> for the $whence argument.

=back

=cut

#
# Flags as recognized by open()
#
our $O_MODE = 0x0003;

our $O_RDONLY = 0x0000;
our $O_WRONLY = 0x0001;
our $O_RDWR   = 0x0002;

our $O_SYNC = 0x0080;

our $O_SHLOCK   = 0x0010;
our $O_EXLOCK   = 0x0020;
our $O_ASYNC    = 0x0040;
our $O_FSYNC    = $O_SYNC;
our $O_NOFOLLOW = 0x0100;

our $O_CREAT = 0x0200;
our $O_TRUNC = 0x0400;
our $O_EXCL  = 0x0800;

our $O_NONBLOCK = 0x0004;
our $O_APPEND   = 0x0008;

our $O_EVTONLY = 0x8000;

#
# Inode format bitfield and values
#
our $S_IFMT = 0170000;

our $S_IFIFO  = 0010000;
our $S_IFCHR  = 0020000;
our $S_IFDIR  = 0040000;
our $S_IFBLK  = 0060000;
our $S_IFREG  = 0100000;
our $S_IFLNK  = 0120000;
our $S_IFSOCK = 0140000;
our $S_IFWHT  = 0160000;

#
# Inode execution protection bitfield and values
#
our $S_IPROT = 0007000;

our $S_ISUID = 0004000;
our $S_ISGID = 0002000;
our $S_ISVTX = 0001000;

#
# Inode permission bitfield and values
#
our $S_IR    = 0000444;
our $S_IW    = 0000222;
our $S_IX    = 0000111;
our $S_IRW   = $S_IR | $S_IW;
our $S_IPERM = $S_IRW | $S_IX;

# Per assigned user
our $S_IRWXU = 0000700;

our $S_IRUSR = 0000400;
our $S_IWUSR = 0000200;
our $S_IXUSR = 0000100;

# Per assigned group
our $S_IRWXG = 0000070;

our $S_IRGRP = 0000040;
our $S_IWGRP = 0000020;
our $S_IXGRP = 0000010;

# All other users
our $S_IRWXO = 0000007;

our $S_IROTH = 0000004;
our $S_IWOTH = 0000002;
our $S_IXOTH = 0000001;

#
# seek() operations
#
our $SEEK_SET = 0x00;
our $SEEK_CUR = 0x01;
our $SEEK_END = 0x02;

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
