#!/usr/bin/perl
use strict; use warnings;
use Fcntl qw( :DEFAULT :mode );	# S_IFREG S_IFDIR, O_SYNC O_LARGEFILE etc

# uncomment this to enable debugging
#sub Filesys::Virtual::Async::inMemory::DEBUG { 1 }

use Filesys::Virtual::Async::inMemory;

# create the filesystem
my $vfs = Filesys::Virtual::Async::inMemory->new;

# use $vfs as you wish!
$vfs->readdir( '/', sub {	# should print out nothing
	my $data = shift;
	if ( defined $data ) {
		foreach my $e ( @$data ) {
			print "entry in / -> $e\n";
		}
		print "end of listing for /\n";
	} else {
		print "error reading /\n";
	}
	do_file_io();
} );

my $fh;
sub do_file_io {
	$vfs->mknod( '/bar', oct( '100644' ), 0, \&did_mknod );
}
sub did_mknod {
	if ( $_[0] == 0 ) {
		# write to it!
		$vfs->open( '/bar', O_RDWR, 0, \&did_open );
	} else {
		print "error mknod /bar\n";
	}
}
sub did_open {
	$fh = shift;
	if ( defined $fh ) {
		my $buf = "foobar";
		$vfs->write( $fh, 0, length( $buf ), $buf, 0, \&did_write );
	} else {
		print "error opening /bar\n";
	}
}
sub did_write {
	my $wrote = shift;
	if ( $wrote ) {
		print "successfully wrote to /bar\n";
		$vfs->close( $fh, \&did_close );
	} else {
		print "error writing to /bar\n";
	}
}
sub did_close {
	my $status = shift;
	if ( $status == 0 ) {
		print "successfuly closed fh\n";
	} else {
		print "error in closing fh\n";
	}
	do_read();
}
sub do_read {
	my $buf;
	$vfs->load( '/bar', $buf, sub {
		my $status = shift;
		if ( $status ) {
			print "read $status bytes from /bar: '$buf'\n";
		} else {
			print "error reading from /bar\n";
		}
	} );
}