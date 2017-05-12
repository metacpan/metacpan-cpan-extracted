#!/usr/bin/env perl

# This Socks Proxy Server allows 4 and 5 version on the same port
# May process many clients in parallel

use strict;
use lib '../lib';
use Coro::PatchSet 0.04;
BEGIN {
	# make IO::Select Coro aware
	package IO::Select;
	use Coro::Select;
	use IO::Select;
}
use IO::Socket::Socks qw(:constants :DEFAULT);
use Coro;
use Coro::Socket;

# make our server Coro aware
$IO::Socket::Socks::SOCKET_CLASS = 'Coro::Socket';

my $server = IO::Socket::Socks->new(SocksVersion => [4,5], ProxyAddr => 'localhost', ProxyPort => 1080, Listen => 10)
	or die $SOCKS_ERROR;

warn "Server started at ", $server->sockhost, ":", $server->sockport;

$server->blocking(0); # accept() shouldn't block main thread
my $server_selector = IO::Select->new($server);

while (1) {
	$server_selector->can_read();
	my $client = $server->accept() # just accept
		or next;                   # without socks handshake
	
	async_pool {
		$client->ready() # and make handshake in separate thread
			or return;
		
		my ($cmd, $host, $port) = @{$client->command};
		
		if ($cmd == CMD_CONNECT) {
			my $sock = Coro::Socket->new(
				PeerAddr => $host,
				PeerPort => $port,
				Timeout  => 10
			);
			
			if ($sock) {
				$client->command_reply(
					$client->version == 4 ? REQUEST_GRANTED : REPLY_SUCCESS,
					$sock->sockhost,
					$sock->sockport
				);
				
				my $selector = IO::Select->new($client, $sock);
				my $buf;
				
				SELECT:
				while (1) {
					my @ready = $selector->can_read();
					
					for my $s (@ready) {
						last SELECT unless $s->sysread($buf, 1024);
						
						if ($s == $client) {
							$sock->syswrite($buf);
						}
						else {
							$client->syswrite($buf);
						}
					}
				}
				
				$sock->close();
			}
			else {
				$client->command_reply(
					$client->version == 4 ? REQUEST_FAILED : REPLY_HOST_UNREACHABLE,
					$host,
					$port
				);
			}
		}
		else {
			$client->command_reply(
				$client->version == 4 ? REQUEST_FAILED : REPLY_CMD_NOT_SUPPORTED,
				$host,
				$port
			);
		}
		
		$client->close();
	};
}

$server->close();
