
use File::Temp;
use Data::Structure::Util qw(unbless);
use IO::Socket::UNIX;
require POSIX;
use Socket;
use IO::Handle;

our $dir;

sub dirwrap
{
	my ($code) = @_;

	my $dirobj = File::Temp->newdir();
	$dir = $dirobj->dirname();

	my $parent = new IO::Handle;
	my $child = new IO::Handle;
	socketpair($parent, $child, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
		or die "cannot create socketpair: $!";

	my $pid = fork();

	if ($pid) {
		unbless $dirobj;

		$parent->close();
		$code->();
		$child->close();
	} elsif (defined $pid) {
		$child->close();
		while(<$parent>) {};
	} else {
		die "could not fork: $!";
	}
	exit(0);
}

1;
