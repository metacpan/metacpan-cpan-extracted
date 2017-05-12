package File::Redirect::Zip;

use strict;
use warnings;

use Errno;
use IO::Scalar;
use Archive::Zip qw(:ERROR_CODES);
use base 'File::Redirect::Base';

sub mount
{
	my ( $class, $file, $dev_no ) = @_;

	my $zip = Archive::Zip-> new;
	($zip-> read($file) == AZ_OK) or die;

	my %files = 
		map { '/' . $_-> fileName => $_ }
		grep { $_-> isa('Archive::Zip::ZipFileMember') } 
		$zip-> members;

	return bless {
		zip    => $zip,
		files  => \%files,
		dev_no => $dev_no,
		time   => time,
	}, $class;
}

sub Stat
{
	my ($self, $path) = @_;

	my $m = $self-> {files}-> {$path};
	return Errno::ENOENT() unless $m;

	my $time = $m-> lastModTime;


	return [                                           
		$self-> {dev_no},                 #  0 dev      device number of filesystem
		0,                                #  1 ino      inode number
		$m-> unixFileAttributes,          #  2 mode     file mode  (type and permissions)
		1,                                #  3 nlink    number of (hard) links to the file
		$<,                               #  4 uid      numeric user ID of file’s owner
		$(,                               #  5 gid      numeric group ID of file’s owner
		0,                                #  6 rdev     the device identifier (special files only)
		$m-> uncompressedSize,            #  7 size     total size of file, in bytes
		$time,                            #  8 atime    last access time in seconds since the epoch
		$time,                            #  9 mtime    last modify time in seconds since the epoch
		$time,                            # 10 ctime    inode change time in seconds since the epoch (*)
		512,                              # 11 blksize  preferred block size for file system I/O
		32                                # 12 blocks   actual number of blocks allocated
	];
}

sub Open
{
	my ( $self, $path, $mode ) = @_;

	my $m = $self-> {files}-> {$path};
	return Errno::ENOENT() unless $m;

	my $contents = $m-> contents;
	return Errno::ENOENT() unless defined $contents; 

	open my $fh, '<', \ $contents or return $!;
	return $fh;
}

1;

=head1 NAME

File::Redirect::Zip - zip vfs

=head1 DESCRIPTION

The second argument to C<mount> is a .zip archive name.

=head1 SYNOPSIS

   mount( 'Zip', '/tmp/archive.zip', 'zip1:') or die;
   open F, '< zip1:/path/file.txt';

=cut
