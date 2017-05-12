package File::Redirect::Simple;

use strict;
use warnings;

use Errno;
use IO::Scalar;
use base 'File::Redirect::Base';

sub mount
{
	my ( $class, $hash, $dev_no ) = @_;

	return bless {
		hash   => $hash,
		dev_no => $dev_no,
		time   => time,
	}, $class;
}

sub Stat
{
	my ($self, $path) = @_;
	return Errno::ENOENT() unless exists $self-> {hash}-> {$path};

	return [                                           
		$self-> {dev_no},                 #  0 dev      device number of filesystem
		0,                                #  1 ino      inode number
		0400,                             #  2 mode     file mode  (type and permissions)
		1,                                #  3 nlink    number of (hard) links to the file
		$<,                               #  4 uid      numeric user ID of file’s owner
		$(,                               #  5 gid      numeric group ID of file’s owner
		0,                                #  6 rdev     the device identifier (special files only)
		length $self-> {hash}-> {$path},  #  7 size     total size of file, in bytes
		$self-> {time},                   #  8 atime    last access time in seconds since the epoch
		$self-> {time},                   #  9 mtime    last modify time in seconds since the epoch
		$self-> {time},                   # 10 ctime    inode change time in seconds since the epoch (*)
		512,                              # 11 blksize  preferred block size for file system I/O
		32                                # 12 blocks   actual number of blocks allocated
	];
}

sub Open
{
	my ( $self, $path, $mode ) = @_;

	return Errno::ENOENT() unless exists $self-> {hash}-> {$path};

	open my $fh, '<', \ $self-> {hash}-> {$path} or return $!;
	return $fh;
}

1;

=head1 NAME

File::Redirect::Simple - simple hash-based vfs

=head1 DESCRIPTION

The second argument to C<mount> is a simple hash, where each entry is a file name
and its content. For example, after call

   mount( 'Simple', { 'a' => 'b' }, 'simple:')

reading from file 'simple:a' yield 'b' as its content.

=cut
