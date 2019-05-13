#!/usr/bin/perl
#$Id: dbi.pl,v 1.13 2012/01/14 10:33:30 dk Exp $
use strict;
use warnings;

use IO::Socket::INET;
use IO::Lambda qw(:all);
use IO::Lambda::DBI;
use IO::Lambda::Thread qw(new_thread);
use IO::Lambda::Fork qw(new_process);
use IO::Lambda::Socket;

my $port = 3333;

sub usage
{
	print <<USAGE;

Test implementation of non-blocking DBI. This script can work in several modes,
run with one of the parameters to switch:

   $0 thread      - use DBI calls in a separate thread
   $0 fork        - use DBI calls in a separate process
   $0 remote HOST - connect to host to port $port and request DBI there
   $0 listen      - listen on port $port, execute incoming connections
	
USAGE
	exit;
}

my $mode = shift(@ARGV) || '';
usage unless $mode =~ /^(fork|thread|remote|listen)$/;

sub check_dbi
{
	my $dbi = shift;
	my $tries = 3;
	lambda {
		my $expect = int rand 100;
		context $dbi-> selectrow_array('SELECT 1 + ?', {}, $expect);
	tail {
		return warn("remote db error:@_\n") unless shift;
		my $ret = -1 + shift;
		print "$expect -> $ret\n";

		if ( $tries--) {
			this-> start;
		}
	}}
}

sub execute
{
	my $dbi = shift;
	lambda {
		context $dbi-> connect('DBI:mysql:database=mysql', '', '');
		tail {
			return warn("remote db connect error:@_\n") unless shift;
			context 
				check_dbi($dbi),
				check_dbi($dbi),
				check_dbi($dbi);
		tails {
			context $dbi-> disconnect;
		&tail();
	}}}-> wait;
}

my %dbopt = ( timeout => 5 );

# run

if ( $mode eq 'thread') {
	die $IO::Lambda::Thread::DISABLED if $IO::Lambda::Thread::DISABLED;

	my ($thread, $socket) = new_thread( sub {
		IO::Lambda::Message::DBI-> new( shift )-> run;
	}, 1);
	
	my $dbi = IO::Lambda::DBI-> new( $socket, $socket, %dbopt);
	execute($dbi);
	undef $dbi;
	
	$thread-> join;

} elsif ( $mode eq 'fork') {
	my ( $pid, $socket) = new_process {
		IO::Lambda::Message::DBI-> new( shift )-> run;
	};
	
	my $dbi = IO::Lambda::DBI-> new( $socket, $socket, %dbopt);
	execute($dbi);
	undef $dbi;

	close($socket);
	waitpid($pid, 0);
} elsif ( $mode eq 'remote') {
	my $host = shift @ARGV;
	usage unless defined $host;

	my $s = IO::Socket::INET-> new("$host:$port");
	die $! unless $s;

	my $dbi = IO::Lambda::DBI-> new( $s, $s, %dbopt);
	execute($dbi);

	undef $s;
} elsif ( $mode eq 'listen') {
	my $s = IO::Socket::INET-> new(
		LocalPort => $port,
		Listen    => 5,
		ReuseAddr => 1,
	);
	die $! unless $s;
	while ( 1) {
		my $c = IO::Handle-> new;
		die $! unless accept( $c, $s);
		eval {
			my $loop = IO::Lambda::Message::DBI-> new($c);
			$loop-> run;
			close($c);
		};
		warn $@ if $@;
	}
}
