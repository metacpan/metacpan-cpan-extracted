# $Id: tcp-lambda-optimized.pl,v 1.1 2009/01/17 11:26:53 dk Exp $
# An echo client-server benchmark
use strict;
use IO::Lambda qw(:all);
use Time::HiRes qw(time);
use IO::Handle;
use IO::Socket::INET;

require IO::Lambda::Loop::AnyEvent if @ARGV and $ARGV[0] eq '--anyevent';

my $CYCLES = 500;

# benchmark in lambdas

my $port      = $ENV{TESTPORT} || 29876;
my $serv_sock = IO::Socket::INET-> new(
	Listen    => 5,
	LocalPort => $port,
	Proto     => 'tcp',
	ReuseAddr => 1,
);
die "listen() error: $!\n" unless $serv_sock;


my $server = lambda {
	context $serv_sock;
	readable {
		my $conn = IO::Handle-> new;

		accept( $conn, $serv_sock) or die "accept() error:$!";
		again;

		context $conn;
		readable {
			my $input = <$conn>;
			print $conn $input if defined $input;
			close $conn;
		};
	};
};
$server-> start;

# prepare connection to the server
sub sock
{
	my $x = IO::Socket::INET-> new(
		PeerAddr  => 'localhost',
		PeerPort  => $port,
		Proto     => 'tcp',
	);
	die "connect() error: $!$^E\n" unless $x;
	return $x;
}

my $t = time;
for my $id (1..$CYCLES) {
	this lambda {
		my $sock = sock;
		context $sock;
		writable {
			print $sock "can write $id\n";
			close $sock;
		};
	};
	this-> wait;
}
$t = time - $t;
printf "%.3f sec\n", $t;
$server-> destroy;
