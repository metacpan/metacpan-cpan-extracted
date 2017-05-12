package Fuse::PerlSSH::RemoteFunctions;

# init read seek tell write truncate close copied from PerlSSH::Library::IO, v0.16, (C) Paul Evans, 2009-2011 -- leonerd@leonerd.org.uk

use strict;
use warnings;

use IPC::PerlSSH::Library;


init q[
use IO::Handle;

our %handles;

sub store_handle {
   my $fh = shift;
   my $fd = $fh->fileno;
   $handles{$fd} = $fh;
   return $fd;
}

sub get_handle {
   my $fd = shift;
   $fd > 2 or die "Cannot operate on STD{IN|OUT|ERR}\n";
   return $handles{$fd} || die "No handle on fileno $fd\n";
}
];

# because FUSE gives us sysopen-style numeric modes, and PerlSSH's open would
# require us to map back to symbols, we implement a sysopen
func sysopen  => q{
	my ( $mode, $path ) = @_;
	sysopen( my $fh, $path, $mode ) or die "Cannot sysopen() - $!\n";
	$fh->autoflush;
	store_handle( $fh );
};

func close => q{
   our %handles;
   undef $handles{shift()};
};

# second arg to seek is WHENCE, 0 is for SEEK_SET
func read => q{
	my $fh = get_handle( shift );
	$fh->seek($_[1], 0) or die "Cannot seek() in read() - $!\n";
	defined( $fh->read( my $buf, $_[0] ) ) or die "Cannot read() - $!\n";
	return $buf;
};

func write => q{
	my $fh = get_handle( shift );
	$fh->seek($_[1], 0) or die "Cannot seek() in write() - $!\n";
	defined( $fh->print( $_[0] ) ) or die "Cannot write() - $!\n";
};

func tell => q{
   my $fh = get_handle( shift );
   return tell($fh);
};

func truncate => q{
   my $fh = get_handle( shift );
   $fh->truncate( $_[0] ) or die "Cannot truncate() - $!\n";
};

func fstat => q{
   my $fh = get_handle( shift );
   my @s = stat( $fh ) or die "Cannot stat() - $!\n";
   @s;
};

1;