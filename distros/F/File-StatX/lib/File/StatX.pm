package File::StatX;
$File::StatX::VERSION = '0.005';
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

use Exporter 'import';
our @EXPORT_OK;
push @EXPORT_OK, qw/statx fstatx statxat/;
our %EXPORT_TAGS = (
	all   => \@EXPORT_OK,
	funcs => [qw/statx fstatx statxat/],
	masks => [ grep /^STATX_/, @EXPORT_OK ],
	at    => [ grep /^AT_/, @EXPORT_OK ],
);

use Carp 'croak';

sub statx {
	my ($path, $flags, $mask) = @_;
	my $result = File::StatX->new;
	_do_statx(undef, $path, $flags, $mask, $result) or croak "Could not statx: $!";
	return $result;
}

sub fstatx {
	my ($fh, $flags, $mask) = @_;
	my $result = File::StatX->new;
	_do_fstatx($fh, $flags, $mask, $result) or croak "Could not statx: $!";
	return $result;
}

sub statxat {
	my ($dir, $path, $flags, $mask) = @_;
	my $result = File::StatX->new;
	_do_statx($dir, $path, $flags, $mask, $result) or croak "Could not statx: $!";
	return $result;
}

1;

# ABSTRACT: StatX for Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

File::StatX - StatX for Perl

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use File::StatX 'statx', ':masks';

 my $stat = statx("filename", 0, STATX_BASIC_STATS);
 say "File size is ", $stat->size;

=head1 DESCRIPTION

This module exposes C<statx> to Perl. This allows XXX

=head1 FUNCTIONS

=head2 statx

 statx($path, $flags, $mask)

This will stat C<$path>. C<$flags> and C<$mask> are bitmask containing any of the L<flag/Flags> and L<mask|/Masks> values documented below.

=head2 statxat

 statx($dir, $path, $flags, $mask)

This will stat C<$path>, using dirhandle C<$dir> as reference if C<$path> is a relative path. C<$flags> and C<$mask> are bitmask containing any of the flag and mask values documented below.

=head2 fstatx

This will stat the file behind filehandle C<$fh>. C<$flags> and C<$mask> are bitmask containing any of the flag and mask values documented below.

=head1 METHODS

=head2 Core methods

=head3 new

This will create a new (empty) File::StatX object.

=head3 mask

This will return the mask of the object; this will tell you which of its values are set.

=head2 Members

These are various members of statx. All are optional, and are only defined is the appropriate mask bit is set (as documented in L<Masks|/Masks>.

=head3 blksize

The "preferred" block size for efficient filesystem I/O. (Writing to a file in smaller chunks may cause an inefficient read-modify-rewrite).

=head3 nlink

The number of hard links on a file.

=head3 uid

This field contains the user ID of the owner of the file.

=head3 gid

This field contains the ID of the group owner of the file.

=head3 mode

The file type and mode. See inode(7) for details.

=head3 ino

The inode number of the file.

=head3 size

The size of the file (if it is a regular file or a symbolic link) in bytes. The size of a symbolic link is the length of the pathname it contains, without a terminating null byte.

=head3 blocks

The number of blocks allocated to the file on the medium, in 512-byte units. (This may be smaller than C<size/512> when the file has holes.)

=head3 dev_major

The major number of the device on which this file (inode) resides.

=head3 dev_minor

The minor number of the device on which this file (inode) resides.

=head3 rdev_major

The major number of the device that this file (inode) represents if the file is of block or character device type.

=head3 rdev_minor

The major number of the device that this file (inode) represents if the file is of block or character device type.

=head3 atime

The file's last access timestamp.

=head3 btime

The file's creation timestamp.

=head3 ctime

The file's last status change timestamp.

=head3 mtime

The file's last modification timestamp.

=head3 mnt_id

If using C<STATX_MNT_ID>, this is the mount ID of the mount containing the file. This is the same number reported by name_to_handle_at(2) and corresponds to the number in the first field in one of the records in /proc/self/mountinfo.

If using C<STATX_MNT_ID_UNIQUE>, this is the unique mount ID of the mount containing the file. This is the number reported by listmount(2) and is the ID used to query the mount with statmount(2). It is guaranteed to not be reused while the system is running.

=head3 subvol

Subvolume number of the current file.

Subvolumes are fancy directories, i.e., they form a tree structure that may be walked recursively. Support varies by filesystem; it is supported by bcachefs and btrfs since Linux 6.10. 

=head3 atomic_write_segments_max

The maximum number of elements in an array of vectors for a write with torn-write protection enabled.

=head3 atomic_write_unit_max

The minimum and maximum sizes (in bytes) supported for direct I/O (O_DIRECT) on the file to be written with torn-write protection. These values are each guaranteed to be a power-of-2.

=head3 atomic_write_unit_min

The minimum and maximum sizes (in bytes) supported for direct I/O (O_DIRECT) on the file to be written with torn-write protection. These values are each guaranteed to be a power-of-2.

=head3 atomic_write_unit_max_opt

The maximum size (in bytes) which is optimised for writes issued with torn-write protection. If non-zero, this value will not exceed the value in C<atomic_write_unit_max> and will not be less than the value in c<atomic_write_unit_min>. A value of zero indicates that c<atomic_write_unit_max> is the optimised limit. Slower writes may be experienced when the size of the write exceeds c<atomic_write_unit_max_opt> (when non-zero).

=head3 dio_mem_align

The alignment (in bytes) required for user memory buffers for direct I/O (O_DIRECT) on this file, or 0 if direct I/O is not supported on this file.

=head3 dio_offset_align

The alignment (in bytes) required for file offsets and I/O segment lengths for direct I/O (O_DIRECT) on this file, or 0 if direct I/O is not supported on this file. This will only be nonzero if c<dio_mem_align> is nonzero, and vice versa.

=head3 dio_read_offset_align

The alignment (in bytes) required for file offsets and I/O segment lengths for direct I/O reads (O_DIRECT) on this file. If zero, the limit in c<dio_offset_align> applies for reads as well. If non-zero, this value must be smaller than or equal to C<dio_offset_align> which must be provided by the file system if requested by the application. The memory alignment in c<dio_mem_align> is not affected by this value.

=head2 Attributes

These extra file attributes contain flags that indicate additional attributes of the file.

=head3 append

The file can only be opened in append mode for writing. Random access writing is not permitted. See chattr(1).

=head3 compressed

The file is compressed by the filesystem and may take extra resources to access.

=head3 dax

The file is in the DAX (cpu direct access) state. DAX state attempts to minimize software cache effects for both I/O and memory mappings of this file. It requires a file system which has been configured to support DAX.

DAX generally assumes all accesses are via CPU load / store instructions which can minimize overhead for small accesses, but may adversely affect CPU utilization for large transfers.

File I/O is done directly to/from user-space buffers and memory mapped I/O may be performed with direct memory mappings that bypass the kernel page cache.

While the DAX property tends to result in data being transferred synchronously, it does not give the same guarantees as the O_SYNC flag (see open(2)), where data and the necessary metadata are transferred together.

A DAX file may support being mapped with the MAP_SYNC flag, which enables a program to use CPU cache flush instructions to persist CPU store operations without an explicit fsync(2). See mmap(2) for more information.

=head3 encrypted

A key is required for the file to be encrypted by the filesystem.

=head3 immutable

The file cannot be modified: it cannot be deleted or renamed, no hard links can be created to this file and no data can be written to it. See chattr(1).

=head3 mount_root

The file is the root of a mount.

=head3 nodump

File is not a candidate for backup when a backup program such as dump(8) is run. See chattr(1).

=head3 verity

The file has fs-verity enabled. It cannot be written to, and all reads from it will be verified against a cryptographic hash that covers the entire file (e.g., via a Merkle tree).

=head3 write_atomic

The file supports torn-write protection.

=head2 Masks

=head3 STATX_TYPE

Want C<mode> & S_IFMT

=head3 STATX_MODE

Want C<mode> & ~S_IFMT

=head3 STATX_NLINK

Want C<nlink>

=head3 STATX_UID

Want C<uid>

=head3 STATX_GID

Want C<gid>

=head3 STATX_ATIME

Want C<atime>

=head3 STATX_MTIME

Want C<mtime>

=head3 STATX_CTIME

Want C<ctime>

=head3 STATX_INO

Want C<ino>

=head3 STATX_SIZE

Want C<size>

=head3 STATX_BLOCKS

Want C<blocks>

=head3 STATX_BASIC_STATS

[All of the above]

=head3 STATX_BTIME

Want C<btime>

=head3 STATX_ALL

The same as C<STATX_BASIC_STATS | STATX_BTIME>.

It is deprecated and should not be used.

=head3 STATX_MNT_ID

Want C<mnt_id>. This will be C<0> if not supported on your system.

=head3 STATX_DIOALIGN

Want C<dio_mem_align> and C<dio_offset_align>. This will be C<0> if not supported on your system.

=head3 STATX_MNT_ID_UNIQUE

Want unique C<mnt_id>. This will be C<0> if not supported on your system.

=head3 STATX_SUBVOL

Want C<subvol>. This will be C<0> if not supported on your system.

=head3 STATX_WRITE_ATOMIC

Want C<atomic_write_unit_min>, C<atomic_write_unit_max>, C<atomic_write_segments_max>, and C<atomic_write_unit_max_opt>. This will be C<0> if not supported on your system.

=head3 STATX_DIO_READ_ALIGN

Want C<dio_read_offset_align>. This will be C<0> if not supported on your system.

=head2 Flags

=head3 AT_NO_AUTOMOUNT

Don't automount the terminal ("basename") component of path if it is a directory that is an automount point. This allows the caller to gather attributes of an automount point (rather than the location it would mount). This flag has no effect if the mount point has already been mounted over.

The C<AT_NO_AUTOMOUNT> flag can be used in tools that scan directories to prevent mass-automounting of a directory of automount points.

All of C<stat(2)>, C<lstat(2)>, and C<fstatat(2)> act as though C<AT_NO_AUTOMOUNT> was set.

=head3 AT_SYMLINK_NOFOLLOW

If path is a symbolic link, do not dereference it: instead return information about the link itself, like lstat(2).

=head3 AT_STATX_FORCE_SYNC

Force the attributes to be synchronized with the server when querying a file on a remote filesystem. This may require that a network filesystem perform a data writeback to get the timestamps correct.

=head3 AT_STATX_DONT_SYNC

Don't synchronize anything with a remote filesystem, but rather just take whatever the system has cached if possible. This may mean that the information returned is approximate, but, on a network filesystem, it may not involve a round trip to the server - even if no lease is held.

=head3 AT_STATX_SYNC_AS_STAT

Do whatever stat(2) does regarding syncing. This is the default and is very much filesystem-specific.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
