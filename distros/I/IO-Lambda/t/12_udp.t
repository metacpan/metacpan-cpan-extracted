#! /usr/bin/perl
# $Id: 12_udp.t,v 1.3 2009/12/06 16:16:32 dk Exp $

use strict;
use warnings;
use Test::More;
use IO::Lambda qw(:lambda :stream);
use Time::HiRes qw(time);
use IO::Socket::INET;
use IO::Lambda::Socket qw(send recv);
	
plan skip_all => "online tests disabled" unless -e 't/online.enabled';
plan tests    => 3;

alarm(10);

my $port      = $ENV{TESTPORT} || 29876;
my $server = IO::Socket::INET-> new(
	LocalPort => $port,
	Blocking  => 0,
	Proto     => 'udp',
);
ok( $server, "udp.connect($@)");

my @results;
my $serv = lambda {
	context $server, 256;
	recv {
		my ($addr, $msg) = @_;
		die "error:$msg\n" unless defined $addr;
		push @results, $msg;
		again unless $msg =~ /^quit/;
	}
};

sub msg 
{
	my $msg = shift;
	lambda {
		my $client = IO::Socket::INET-> new(
			PeerAddr  => 'localhost',
			PeerPort  => $port,
			Proto     => 'udp',
			Blocking  => 0,
		);
		context $client, $msg;
	send {
		die "send error:$_[1]\n" unless $_[0];
	}}
}

# 
@results = ();
$serv-> reset;
msg("quit")-> wait;
$serv-> wait;
ok( 1 == @results && $results[0] eq 'quit', 'udp single connection');

# 
@results = ();
$serv-> reset;
msg("1")-> wait;
msg("2")-> wait;
msg("3")-> wait;
msg("quit")-> wait;
$serv-> wait;
ok( 4 == @results && join('', @results) eq '123quit', 'udp multiple connections');
