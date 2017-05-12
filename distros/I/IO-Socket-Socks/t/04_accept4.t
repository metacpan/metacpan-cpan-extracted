#!/usr/bin/env perl

use Test::More;
use IO::Socket::Socks qw(:DEFAULT :constants);
use IO::Select;
use strict;
use Cwd;
require(getcwd."/t/subs.pm");

my $server = IO::Socket::Socks->new(Listen => 10, Blocking => 0, SocksVersion => 4, SocksResolve => 1)
	or die $@;
my $read_select = IO::Select->new($server);
my $serveraddr = fix_addr($server->sockhost);
my $serverport = $server->sockport;

my %local_clients;
for (1..10) {
	my $client = IO::Socket::Socks->new(Blocking => 0, ProxyAddr => $serveraddr, ProxyPort => $serverport, ConnectAddr => '2gis.com',
	                                    ConnectPort => 8080, SocksVersion => 4, SocksResolve => 1);
	ok(defined($client), "Socks 4 client non-blocking connection $_ started");
	$local_clients{$client} = $client;
}

my $accepted = 0;
my $i = 0;
my %server_clients;
while ($accepted != 10 && $i < 30) {
	$i++;
	if ($read_select->can_read(0.5)) {
		my $client = $server->accept();
		$accepted++;
		ok($client, "Socks 4 accept() $accepted") or diag $SOCKS_ERROR;
        is($client->version, 4, 'Client version is 4');
		if ($client) {
			$client->blocking(0);
			$server_clients{$client} = $client;
		}
	}
}

is(scalar keys %server_clients, 10, "All socks 4 clients accepted");
$read_select->remove($server);
my $write_select = IO::Select->new();
$i = 0;

do {
	$i++;
	my @ready;
	if ($read_select->count() || $write_select->count()) {
		if ($read_select->count()) {
			push @ready, $read_select->can_read(0.5);
		}
		
		if ($write_select->count()) {
			push @ready, $write_select->can_write(0.5);
		}
	}
	else {
		@ready = (values %local_clients, values %server_clients);
	}
	
	for my $client (@ready) {
		$read_select->remove($client);
		$write_select->remove($client);
		
		if ($client->ready) {
			if (exists $local_clients{$client}) {
				delete $local_clients{$client};
			}
			else {
				$client->command_reply(REQUEST_GRANTED, '127.0.0.1', '1080');
				delete $server_clients{$client};
			}
		}
		elsif ($SOCKS_ERROR == SOCKS_WANT_READ) {
			$read_select->add($client);
		}
		elsif ($SOCKS_ERROR == SOCKS_WANT_WRITE) {
			$write_select->add($client);
		}
		else {
			fail("Socks 4 no error"); diag $SOCKS_ERROR;
		}
	}
	
} while (%server_clients && $i < 30);

$server->close();
ok(!%server_clients, "All socks 4 connections accepted properly") or diag((scalar keys %server_clients) . " connections was not completed");

done_testing();
