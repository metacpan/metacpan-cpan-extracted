#!/usr/bin/env perl

package IO::Socket::Socks::Slow;

use Socket;
use IO::Socket::Socks qw(:constants);
use base 'IO::Socket::Socks';
use strict;

our $DELAY = 0;

*_fail = \&IO::Socket::Socks::_fail;

sub _socks4_connect_command
{
	my $self = shift;
	my $command = shift;
	my $debug = IO::Socket::Socks::Debug->new() if ${*$self}->{SOCKS}->{Debug};
	my ($reads, $sends, $debugs) = (0, 0, 0);
	my $resolve = defined(${*$self}->{SOCKS}->{Resolve}) ? ${*$self}->{SOCKS}->{Resolve} : $IO::Socket::Socks::SOCKS4_RESOLVE;
	
	my $dstaddr = $resolve ? inet_aton('0.0.0.1') : inet_aton(${*$self}->{SOCKS}->{CmdAddr});
	my $dstport = pack('n', ${*$self}->{SOCKS}->{CmdPort});
	my $userid  = ${*$self}->{SOCKS}->{Username} || '';
	my $dsthost = '';
	if($resolve)
	{ # socks4a
		$dsthost = ${*$self}->{SOCKS}->{CmdAddr} . pack('C', 0);
	}
	
	my $reply;
	my $request = pack('CC', SOCKS4_VER, $command) . $dstport . $dstaddr . $userid . pack('C', 0) . $dsthost;
	my $sent = 0;
	
	while ($request =~ /(..{0,3})/g) {
		$reply = $self->_socks_send($1, ++$sends)
			or return _fail($reply);
		
		$sent += length($1);
		last if $sent == length($request);
		
		sleep $DELAY;
	}
		
	if($debug && !$self->_debugged(++$debugs))
	{
		$debug->add(
			ver => SOCKS4_VER,
			cmd => $command,
			dstport => ${*$self}->{SOCKS}->{CmdPort},
			dstaddr => length($dstaddr) == 4 ? inet_ntoa($dstaddr) : undef,
			userid => $userid,
			null => 0
		);
		if($dsthost)
		{
			$debug->add(
				dsthost => ${*$self}->{SOCKS}->{CmdAddr},
				null => 0
			);
		}
		$debug->show('Client Send: ');
	}
	
	return 1;
}

package main;

use Test::More;
use IO::Socket::Socks;
use IO::Select;
use Time::HiRes;
use strict;
use Cwd;
require(getcwd."/t/subs.pm");

use constant CONN_CNT => 3;

unless ($ENV{SOCKS_SLOW_TESTS} || $ENV{AUTOMATED_TESTING}) {
	plan skip_all => "SOCKS_SLOW_TESTS environment variable should has true value";
}

if( $^O eq 'MSWin32' ) {
	plan skip_all => 'Fork and Windows are incompatible';
}

my %childs;
my @pipes;
my %map = (
	1 => {host => 'google.com', port => 80, request => 'wtf', response => 'googlre response'},
	2 => {host => '2gis.ru', port => 22, request => 'defined', response => 'johny'},
	3 => {host => 'academ.info', port => 110, request => 'make', response => 'segmentation fault'},
);

for my $d (1..CONN_CNT) {
	pipe my $reader, my $writer;
	push @pipes, $writer;
	
	defined (my $child = fork())
		or die "fork(): $!";
	if ($child == 0) {
		close $writer;
		chomp(my $servinfo = <$reader>);
		my ($host, $port) = split /\|/, $servinfo;
		close $reader;
		
		$IO::Socket::Socks::Slow::DELAY = $d;
		my $cli = IO::Socket::Socks::Slow->new(ProxyAddr => $host, ProxyPort => $port, ConnectAddr => $map{$d}{host},
		                                       ConnectPort => $map{$d}{port}, SocksVersion => 4, SocksResolve => 1) or die $@;
		$cli->syswrite("$d:$map{$d}{request}")
			or die $!;
		$cli->sysread(my $buf, 1024)
			or die $!;
		$buf eq $map{$d}{response}
			or die "$buf != $map{$d}{response}";
		
		exit 0;
	}
	
	$childs{$child} = 1;
}

my $server = IO::Socket::Socks->new(Blocking => 0, Listen => 10, SocksVersion => 4, SocksResolve => 1)
	or die $@;

my $host = fix_addr($server->sockhost);
my $port = $server->sockport;

print $_ "$host|$port\n" for @pipes;
close $_ for @pipes;

my $sel_read  = IO::Select->new($server);
my $sel_write = IO::Select->new();

my $conn_cnt = 0;
while ($conn_cnt < CONN_CNT || $sel_read->count() > 1 || $sel_write->count() > 0) {
	my @ready;
	push @ready, $sel_read->can_read(0.3);
	push @ready, $sel_write->can_write(0.3);
	
	foreach my $socket (@ready) {
		my $start = Time::HiRes::time();
		if ($socket == $server) {
			my $client = $server->accept();
			ok($client, "New client connection") or diag $SOCKS_ERROR;
			$client->blocking(0);
			$socket = $client;
			$conn_cnt++;
		}
		
		if ($socket->ready) {
			$socket->command_reply(IO::Socket::Socks::REQUEST_GRANTED, '127.0.0.1', $socket->command->[2]);
			IO::Select->new($socket)->can_read;
			
			ok(defined $socket->sysread(my $request, 1024), "sysread() success") or diag $!;
			my ($d, $r) = $request =~ /(\d+):(.+)/;
			
			ok(defined $d, "Correct key") or diag $request;
			is($r, $map{$d}{request}, "Correct request");
			
			ok(defined $socket->syswrite($map{$d}{response}), "syswrite() success") or diag $!;
			$sel_read->remove($socket);
			$sel_write->remove($socket);
			$socket->close();
		}
		elsif ($SOCKS_ERROR == SOCKS_WANT_READ) {
			$sel_write->remove($socket);
			$sel_read->add($socket);
		}
		elsif ($SOCKS_ERROR == SOCKS_WANT_WRITE) {
			$sel_read->remove($socket);
			$sel_write->add($socket);
		}
		else {
			ok(0, '$SOCKS_ERROR is known') or diag $SOCKS_ERROR;
		}
		
		my $res = Time::HiRes::time() - $start;
		ok($res < 1, "ready() not blocked") or diag "$res sec spent";
	}
}

while (%childs) {
	my $child = wait();
	is($?, 0, "Client $child finished successfully");
	delete $childs{$child};
}

done_testing();
