#! perl

use strict;
use warnings;

use Test::More;

use IO::Uring;
use Socket qw/AF_UNIX SOCK_STREAM PF_UNSPEC/;

my $ring = IO::Uring->new(32);
socketpair(my $client, my $server, AF_UNIX, SOCK_STREAM, PF_UNSPEC);

my @messages = ('Hello world!', 'Goodbye earth');
my @server_expected = @messages;
my @client_received;

sub server_read {
	my ($fh) = @_;
	my $buffer = "\0" x 512;

	$ring->recv($fh, $buffer, 0, 0, 0, sub {
		my ($res, $flags) = @_;
		if ($res < 0) {
			$! = -$res;
			die "Could not recv: $!";
		}
		return unless $res;

		my $received = substr($buffer, 0, $res);
		my $expected = shift @server_expected;
		is $received, $expected, "Server expected $expected";
		server_send($fh, $received);
	});
}

sub server_send {
	my ($fh, $buffer) = @_;
	$ring->send($fh, $buffer, 0, 0, 0, sub {
		my ($res, $flags) = @_;
		if ($res < 0) {
			$! = -$res;
			die "Could not recv: $!";
		}

		if ($res < length $buffer) {
			server_send($fh, substr($buffer, $res));
		} else {
			server_read($fh);
		}
	});
}

server_read($server);

my $continue = 1;

sub client_write {
	my ($fh) = @_;
	my $message = shift @messages;
	$ring->send($fh, $message, 0, 0, 0, sub {
		my ($res, $flags) = @_;
		die if $res < 0;
		my $response = "\0" x 16;
		$ring->recv($fh, $response, 0, 0, 0, sub {
			my ($res, $flags) = @_;
			die if $res < 0;
			is substr($response, 0, $res), $message, "Expected $message, got $res bytes";
			push @client_received, $response;
		});
		client_write($fh) if @messages;
	})
}

client_write($client);

$ring->run_once while @client_received < 2;

done_testing 4;
