#!/usr/bin/env perl

package IO::Socket::Socks::Slow;

use IO::Socket::Socks qw(:constants);
use base 'IO::Socket::Socks';
use strict;

our $DELAY = 0;

*_fail = \&IO::Socket::Socks::_fail;

sub _socks5_connect
{
	my $self = shift;
	my $debug = IO::Socket::Socks::Debug->new() if ${*$self}->{SOCKS}->{Debug};
	my ($reads, $sends, $debugs) = (0, 0, 0);
	my $sock = defined( ${*$self}->{SOCKS}->{TCP} ) ?
				${*$self}->{SOCKS}->{TCP}
				:
				$self;
	
	my $nmethods = 0;
	my $methods;
	foreach my $method (0..$#{${*$self}->{SOCKS}->{AuthMethods}})
	{
		if (${*$self}->{SOCKS}->{AuthMethods}->[$method] == 1)
		{
			$methods .= pack('C', $method);
			$nmethods++;
		}
	}
	
	my $reply;
	my $request = pack('CCa*', SOCKS5_VER, $nmethods, $methods);
	my @p = $request =~ /(..?)/g;

	my $sent = 0;
	while ($request =~ /(..?)/g) {
		$reply = $sock->_socks_send($1, ++$sends)
			or return _fail($reply);
		
		$sent += length($1);
		last if $sent == length($request);
		
		sleep $DELAY;
	}
	
	if($debug && !$self->_debugged(++$debugs))
	{
		$debug->add(
			ver => SOCKS5_VER,
			nmethods => $nmethods,
			methods => join('', unpack("C$nmethods", $methods))
		);
		$debug->show('Client Send: ');
	}
	
	$reply = $sock->_socks_read(2, ++$reads)
		or return _fail($reply);
	
	my ($version, $auth_method) = unpack('CC', $reply);

	if($debug && !$self->_debugged(++$debugs))
	{
		$debug->add(
			ver => $version,
			method => $auth_method
		);
		$debug->show('Client Recv: ');
	}
	
	if ($auth_method == AUTHMECH_INVALID)
	{
		$IO::Socket::Socks::SOCKS_ERROR = $IO::Socket::Socks::CODES{AUTHMECH}->[$auth_method];
		return;
	}

	return $auth_method;
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
		my $cli = IO::Socket::Socks::Slow->new(ProxyAddr => $host, ProxyPort => $port, ConnectAddr => $map{$d}{host}, ConnectPort => $map{$d}{port})
			or die $@;
		
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

my $server = IO::Socket::Socks->new(Blocking => 0, Listen => 10)
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
			$socket->command_reply(IO::Socket::Socks::REPLY_SUCCESS, '127.0.0.1', $socket->command->[2]);
			IO::Select->new($socket)->can_read;
			ok(defined $socket->sysread(my $request, 1024), "sysread() success") or diag $!;
			my ($d, $r) = $request =~ /(\d+):(.+)/;
			
			ok(defined $d, "Correct key") or diag $request;
			is($r, $map{$d}{request}, "Correct request");
			is($socket->command->[1], $map{$d}{host}, "Command host ok");
			is($socket->command->[2], $map{$d}{port}, "Command port ok");
			
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
		
		my $time_spent = Time::HiRes::time() - $start;
		ok($time_spent < 1, "ready() not blocked") or diag "$time_spent sec spent";
	}
}

while (%childs) {
	my $child = wait();
	is($?, 0, "Client $child finished successfully");
	delete $childs{$child};
}

done_testing();
