#!/usr/bin/perl

use Device::Velleman::K8055::Server;
use Proc::Daemon;
use Tie::Hash;

$SIG{HUP} = 'shutdown';


foreach my $argnum (0 .. $#ARGV) {

	if( $ARGV[$argnum] eq '--debug' ) {
		$debug=1;
	}
	if( $ARGV[$argnum] eq '--nodaemon' ) {
		$nodaemon=1;
	}
	
	if( $ARGV[$argnum] eq '--server' ) {
		$server=1;
	}

	if( $ARGV[$argnum] eq '--clientlist' ) {
		$manage=1;
		$clientlist=1;
				
	}
	
	
}


if($server) {
	print "Running Server\n";
	server();
}


sub server {
	#Run as Daemon unless -nodaemon passed.
	unless( $nodaemon ) {
		print "Running as daemon.\n";
		Proc::Daemon::Init;
	}
	my $server = Device::Velleman::K8055::Server->new();
	$server->run;
}



sub shutdown {
	$server->cleanup();
	exit;
}
