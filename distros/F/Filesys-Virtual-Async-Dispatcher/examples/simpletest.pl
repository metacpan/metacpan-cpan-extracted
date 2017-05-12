#!/usr/bin/perl
use strict; use warnings;
use Fcntl qw( :DEFAULT :mode );	# S_IFREG S_IFDIR, O_SYNC O_LARGEFILE etc

# uncomment this to enable debugging
#sub Filesys::Virtual::Async::Dispatcher::DEBUG { 1 }

use Filesys::Virtual::Async::Plain;
use Filesys::Virtual::Async::Dispatcher;

# create the root filesystem
my $rootfs = Filesys::Virtual::Async::Plain->new( 'root' => $ENV{'PWD'} );

# create the extra filesystems
my $tmpfs = Filesys::Virtual::Async::Plain->new( 'root' => '/tmp' );
my $procfs = Filesys::Virtual::Async::Plain->new( 'root' => '/proc' );

# put it all together
my $vfs = Filesys::Virtual::Async::Dispatcher->new( 'rootfs' => $rootfs );
$vfs->mount( '/tmp', $tmpfs );
$vfs->mount( '/tmp/proc', $procfs );

# use $vfs as you wish!
$vfs->readdir( '/', sub {	# should access the $rootfs object
	my $data = shift;
	if ( defined $data ) {
		foreach my $e ( @$data ) {
			print "entry in / -> $e\n";
		}
		print "end of listing for /\n";
	} else {
		print "no data in /\n";
	}
	part_one();
} );

sub part_one {
	$vfs->readdir( '/tmp/proc', sub {	# should access the $procfs object
		my $data = shift;
		if ( defined $data ) {
			foreach my $e ( @$data ) {
				print "entry in /tmp/proc -> $e\n";
			}
			print "end of listing for /tmp/proc\n";
		} else {
			print "error reading /tmp/proc\n";
		}
		part_two();
	} );
}

sub part_two {
	$vfs->open( '/tmp/proc/uptime', O_RDONLY, 0, sub {
		my $fh = shift;
		if ( defined $fh ) {
			my $buf = "";
			$vfs->read( $fh, 0, 1024, $buf, 0, sub {
				if ( $_[0] > 0 ) {
					print "read $_[0] bytes buf: <$buf>\n";
					$vfs->close( $fh, sub {
						print "close status: $_[0]\n";
						part_three();
					} );
				} else {
					print "FAILED TO READ: $!\n";
				}
			} );
		} else {
			print "FAILED TO OPEN: $!\n";
		}
	} );
}

sub part_three {
	if ( ! $vfs->umount( '/tmp/proc' ) ) {
		print "FAILED TO UMOUNT\n";
	} else {
		$vfs->readdir( '/tmp/proc', sub {       # should access the $tmpfs object
			my $data = shift;
			if ( defined $data ) {
				foreach my $e ( @$data ) {
					print "entry in /tmp/proc -> $e\n";
				}
				print "end of listing for /tmp/proc\n";
			} else {
				print "error reading /tmp/proc\n";
			}
		} );
	}
}
