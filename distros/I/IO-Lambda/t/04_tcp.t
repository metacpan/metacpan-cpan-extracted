#! /usr/bin/perl
# $Id: 04_tcp.t,v 1.14 2009/01/08 15:23:26 dk Exp $

use strict;
use warnings;
use Test::More;
use IO::Lambda qw(:lambda :stream);
use Time::HiRes qw(time);
use IO::Handle;
use IO::Socket::INET;

plan skip_all => "online tests disabled" unless -e 't/online.enabled';
plan tests    => 6;

alarm(10);

my $port      = $ENV{TESTPORT} || 29876;
my $serv_sock = IO::Socket::INET-> new(
	Listen    => 5,
	LocalPort => $port,
	Proto     => 'tcp',
	ReuseAddr => 1,
);
die "listen() error: $!\n" unless $serv_sock;
my $last_session_response = '';

sub session
{ 
	my $conn = shift;
	lambda {
		my $buf  = '';
		context $conn, 0.3;
	readable {
		unless ( shift) {
			print $conn "timeout\n";
			return 'timed out';
		}
		my $n = sysread( $conn, $buf, 16384, length($buf));
		return "sysread error:$!" unless defined $n;
		return "closed remotely" unless $n;
		print $conn "read $n bytes\n";
		if ( length($buf) > 128) {
			print $conn "enough\n";
			return 'got fed up';
		} 
		again;
	}}
}

my $server = lambda {
	context $serv_sock;
	readable {
		my $conn = IO::Handle-> new;

		accept( $conn, $serv_sock) or die "accept() error:$!";
		$conn-> autoflush(1);
		again;

		context session($conn);
		tail {
			$last_session_response = shift;
			close $conn;
		};
	};
};
ok( $server-> is_passive, 'server is created' );
$server-> start;
ok( $server-> is_waiting, 'server is alive' );

# prepare connection to the server
sub sock
{
	my $x = IO::Socket::INET-> new(
		PeerAddr  => 'localhost',
		PeerPort  => $port,
		Proto     => 'tcp',
	);
	die "connect() error: $!\n" unless $x;
	return $x;
}

# test that connection works at all
this lambda {
	context sock;
	writable { "can write" };
};
ok( this-> wait eq 'can write', 'got write');

# test that we can write and can read response
this lambda {
	my $c = sock;
	context $c;
	writable {
		print $c "moo";
		context getline, $c, \(my $buf = '');
		tail {
			$_ = shift;
			chomp;
			return $_;
		};
	};
};
ok(this-> wait eq 'read 3 bytes', 'got echo');

## test that we can do the same in parallel
sub conn
{
	my $id = shift;
	lambda {
		my $c = sock;
		context $c;
		writable {
			print $c "moo$id";
			readable {
				$_ = <$c>;
				chomp;
				close $c;
				return $_;
			}
		}
	};
}

this lambda {
	context map { conn $_ } (1,22,333,4444);
	tails { join '+', sort map { m/(\d+)/ } @_ };
};
ok(this-> wait eq '4+5+6+7', 'parallel connections');
# finally test the timeout

this lambda {
	my $c = sock;
	context $c      and writable  {
	context 0.5     and timeout   {
	context $c      and readable  {
	my $resp = <$c>;
	chomp $resp;
	close $c;
	return $resp;
}}}};
ok(this-> wait eq 'timeout', 'timeout');
