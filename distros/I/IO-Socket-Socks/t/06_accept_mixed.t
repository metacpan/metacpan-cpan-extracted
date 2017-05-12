#!/usr/bin/env perl

use Test::More;
use IO::Socket::Socks qw(:DEFAULT :constants);
use IO::Select;
use strict;
use Cwd;
require(getcwd."/t/subs.pm");

my $server = IO::Socket::Socks->new(Listen => 10, Blocking => 0, SocksVersion => [4,5], SocksResolve => 1)
    or die $@;
my $read_select = IO::Select->new($server);
my $serveraddr = fix_addr($server->sockhost);
my $serverport = $server->sockport;

my %local_clients;
my $ver4_cnt = 0;
my $ver5_cnt = 0;
for (1..10) {
    my $ver = rand() < 0.5 ? 4 : 5;
    $ver == 4 ? $ver4_cnt++ : $ver5_cnt++;
    my $client = IO::Socket::Socks->new(SocksVersion => $ver, Blocking => 0, ProxyAddr => $serveraddr, ProxyPort => $serverport, ConnectAddr => '2gis.com', ConnectPort => 8080, SocksResolve => 1);
    ok(defined($client), "Socks $ver client non-blocking connection $_ started");
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
        ok($client, "Socks mixed accept() $accepted") or diag $SOCKS_ERROR;
        if ($client) {
            $client->blocking(0);
            $server_clients{$client} = $client;
        }
    }
}

is(scalar keys %server_clients, 10, "All socks mixed clients accepted");
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
                if ($client->version == 4) {
					$client->command_reply(REQUEST_GRANTED, '127.0.0.1', '1080');
					$ver4_cnt--;
				}
				else {
					$client->command_reply(REPLY_SUCCESS, '127.0.0.1', '1080');
					$ver5_cnt--;
				}
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
            fail("Socks mixed no error");
            diag $SOCKS_ERROR;
        }
    }
    
} while (%server_clients && $i < 30);

$server->close();
is($ver4_cnt, 0, "all socks4 accepted");
is($ver5_cnt, 0, "all socks5 accepted");
ok(!%server_clients, "All socks mixed connections accepted properly") or diag((scalar keys %server_clients) . " connections was not completed");

done_testing();
