use v5.36;
use lib "lib";
use lib "blib/lib";
use lib "blib/arch";

use IO::FD;
use Benchmark qw<cmpthese>;
use Socket ":all";

my @families=(INET=>AF_INET, INET6=>AF_INET6, UNIX=>AF_UNIX);
for my($name,$value)(@families){
	cmpthese -1, {
		"perl_socket_$name"=>sub { socket my $socket,$value, SOCK_STREAM,0; close $socket},
		"iofd_socket_$name"=>sub { IO::FD::socket my $socket,$value, SOCK_STREAM,0; IO::FD::close $socket},
	};
}

