use v5.36;
use lib "lib";
use lib "blib/lib";
use lib "blib/arch";
use IO::FD;
use POSIX;
use Benchmark qw<cmpthese>;

use Fcntl;
my $filename=IO::FD::mktemp("/tmp/emptyfileXXXXXXXXX");
`touch $filename`;

#Compares raw open and close operations of a file
sub file_handle {
	die "Error opening file" unless sysopen my $fh, $filename, O_RDONLY, 0;
	die "Error closeing file" unless close $fh;
}
sub file_desc_posix {
	die "Error opening file" unless my $fd =POSIX::open $filename, O_RDONLY, 0;
	die "Error closeing file" unless POSIX::close $fd;
}

sub io_fd{
	die "Error opening file" unless IO::FD::sysopen my $fd, $filename, O_RDONLY, 0;
	die "Error closeing file" unless IO::FD::close $fd;
}

cmpthese -1, {
	file_handle=>\&file_handle,
	file_desc_posix=>\&file_desc_posix,
	io_fd=>\&io_fd
};



