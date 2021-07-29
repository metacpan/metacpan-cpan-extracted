#!/usr/bin/env perl

use strict;
use warnings;

use FCGI;
use FCGI::Client;
use File::Temp qw(tempfile);
use IO::Socket::UNIX;
use Test::More 'tests' => 4;

my (undef, $unix_socket_file) = tempfile();
my $fcgi_socket = FCGI::OpenSocket($unix_socket_file, 5);

# Client
if (my $pid = fork()) {
	my $right_ret = <<'END';
Content-Type: text/plain

END

	my ($stdout, $stderr) = client_request($unix_socket_file);
	is($stdout, $right_ret."0\n", 'Test first round on stdout.');
	is($stderr, undef, 'Test first round on stderr.');

	($stdout, $stderr) = client_request($unix_socket_file);
	is($stdout, $right_ret."1\n", 'Test second round on stdout.');
	is($stderr, undef, 'Test second round on stderr.');

# Server
} elsif (defined $pid) {
	my $request = FCGI::Request(\*STDIN, \*STDOUT, \*STDERR, \%ENV, $fcgi_socket);

	# Only two cycles.
	my $count = 0;
	while ($count < 2 && $request->Accept() >= 0) {
		print "Content-Type: text/plain\n\n";
		print $count++."\n";
	}
	exit;

} else {
	die $!;
}

# Cleanup.
FCGI::CloseSocket($fcgi_socket);
unlink $unix_socket_file;

sub client_request {
	my $unix_socket_file = shift;

	my $sock = IO::Socket::UNIX->new(
		Peer => $unix_socket_file,
	) or die $!;
	my $client = FCGI::Client::Connection->new(sock => $sock);
	my ($stdout, $stderr) = $client->request({
		REQUEST_METHOD => 'GET',
	}, '');

	return ($stdout, $stderr);
}
