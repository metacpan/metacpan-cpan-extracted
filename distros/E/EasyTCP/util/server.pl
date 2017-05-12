#!/usr/local/bin/perl

#
# $Header: /cvsroot/Net::EasyTCP/util/server.pl,v 1.5 2003/02/28 19:50:10 mina Exp $
#

use Net::EasyTCP;
$| = 1;

print "Creating server ...\n";
$server = new Net::EasyTCP(
	mode    => "server",
	port    => 2345,
	welcome => "Welcome to my first little echo server",
  )
  || die "ERROR CREATING SERVER: $@\n";

print "Setting callbacks ...\n";
$server->setcallback(
	data       => \&gotdata,
	connect    => \&connected,
	disconnect => \&disconnected,
  )
  || die "ERROR SETTING CALLBACKS: $@\n";

print "Starting server ...\n\n";
$server->start() || die "ERROR STARTING SERVER: $@\n";

sub gotdata() {
	my $client = shift;
	my $serial = $client->serial();
	my $data   = $client->data();
	print "Client $serial sent me some data, sending it right back to them again\n";
	$client->send($data) || die "ERROR SENDING TO CLIENT: $@\n";
	if ($data eq "QUIT") {
		$client->close() || die "ERROR CLOSING CLIENT: $@\n";
	}
	elsif ($data eq "DIE") {
		$server->stop() || die "ERROR STOPPING SERVER: $@\n";
	}
}

sub connected() {
	my $client = shift;
	my $serial = $client->serial();
	my $ip     = $client->remoteip();
	my $port   = $client->remoteport();
	print "Client $serial [$ip:$port] just connected\n";
}

sub disconnected() {
	my $client = shift;
	my $serial = $client->serial();
	print "Client $serial just disconnected\n";
}

