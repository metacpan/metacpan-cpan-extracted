#!/usr/bin/perl -w

use strict;
use FUSE::Server;

my $server;

$server = FUSE::Server->new({Port=>35008, MaxClients=>5000, Quiet=>0});

my $data = $server->bind();
print "Server started on $data...\n";

$server->addCallback('BROADCASTALL',\&msg_broadcast);
$server->addCallback('client_start',\&msg_client_start);
$server->addCallback('client_stop',\&msg_client_stop);
$server->defaultCallback(\&unknown_command);

$SIG{INT} = $SIG{TERM} = $SIG{HUP} = sub{$server->stop();};

$server->start();

####################


sub msg_broadcast{
	my ($sock,$msg,$params) = @_;
	my @a = split /\//,$params;
	$server->sendAll($a[1],$a[2]);
}

sub msg_client_start{
	my ($sock,$msg,$params) = @_;
	$server->send($sock,'SECRET_KEY','123 456 789');
}

sub msg_client_stop{
	my ($sock,$msg,$params) = @_;
}

sub unknown_command{
	my ($sock,$msg,$params) = @_;
	print "Unknown command $msg ($params)\n";
}
