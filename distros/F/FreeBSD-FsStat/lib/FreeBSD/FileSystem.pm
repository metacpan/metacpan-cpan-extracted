package FreeBSD::FileSystem;
$FreeBSD::FileSystem::VERSION = '0.107';
use v5.20;
use strict;
use warnings;

use Moose;

# ABSTRACT:  Query a FreeBSD system for the list of mounted filesystems

=head1 NAME

FreeBSD::FileSystem - Class representing a filesystem in a FreeBSD host

=head1 VERSION

version 0.107

=head1 SYNOPSIS

 my @fsystems = FreeBSD::FsStat::get_filesystems;
 for my $fs ( @fsystems ) {
   say $fs->mountpoint.' '.$fs->pct_avail
 }

=head1 DESCRIPTION

This class encapsulates a FreeBSD filesystem information.

=head1 METHODS

=over 2

=cut


=item type

Returns string representation of the type of this filesystem

=cut

has type => (
	is 		=> 'ro',
	isa		=> 'Str',
	init_arg	=> 'f_fstypename',
);

=item device

Returns the device corresponding to this filesystem.

=cut


has device => (
	is		=> 'ro',
	isa		=> 'Str',
	init_arg	=> 'f_mntfromname',
);

=item mountpoint

Returns the directory where this filesystem is mounted.

=cut

has mountpoint => (
	is		=> 'ro',
	isa		=> 'Str',
	init_arg	=> 'f_mntonname',
);

=item blocksize

Returns the block size for this filesystem. L<Statfs(2)> refers to this as
the 'filesystem fragment size'.

=item iosize

Optimal transfer block size for this filesystem.

=item blocks

Returns the number of total data blocks in filesystem.

=item free_blocks

Returns the number of free blocks in filesystem.

=item avail_blocks

Returns the number of free blocks avail to non-superuser.

=item inodes

Returns the number of total file nodes in filesystem.

=cut

my %attrs = (
	blocksize	=> 'f_bsize',
	iosize		=> 'f_iosize',
	blocks		=> 'f_blocks',
	free_blocks	=> 'f_bfree',
	avail_blocks	=> 'f_bavail',
	inodes		=> 'f_files',
	avail_inodes	=> 'f_ffree',
);

for my $attr (keys %attrs) {
	has $attr => (
		is		=> 'ro',
		isa		=> 'Num',
		init_arg	=> $attrs{$attr},
	)
}

=item size

Returns the size of this filesystem in bytes.

=cut

sub size {
	$_[0]->blocks * $_[0]->blocksize
}

=item free

Returns the number of free bytes in this filesystem.

=cut

sub free {
	$_[0]->free_blocks * $_[0]->blocksize
}

=item avail

Returns the number of bytes in this filesystem which are available
to a non-superuser.

=cut

sub avail {
	$_[0]->avail_blocks * $_[0]->blocksize
}

=item pct_free

Percentage of filesystem size that is free.

=cut

sub pct_free {
	100 * $_[0]->free_blocks / $_[0]->blocks
}

=item pct_avail

Percentage of filesystem size that is available

=back
=cut

sub pct_avail {
	100 * $_[0]->avail_blocks / $_[0]->blocks
}

1;
