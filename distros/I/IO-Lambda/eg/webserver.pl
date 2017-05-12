#!/usr/bin/perl
# $Id: webserver.pl,v 1.5 2010/03/12 23:01:47 dk Exp $
#
=pod

This example features a minimalistic web server, that can only maintain
a counter in a http session. It uses persistent connections of HTTP/1.1,
and keeps one counter per connection. The session expires in $conn_timeout
automatically.

Open two browsers (not just two windows/tabs of the same, browsers are
smart now and share connections) and see how each has its own counter.

=cut

use strict;
use IO::Socket;
use HTTP::Request;
use HTTP::Response;
use IO::Lambda qw(:all);
use IO::Lambda::Socket qw(:all);


my $port = 8080;
my $conn_timeout = 10;

my $server = IO::Socket::INET-> new(
	Listen    => 5,
	LocalPort => $port,
	Blocking  => 0,
	ReuseAddr => 1,
);
die $! unless $server;

$port = $ARGV[0] if $ARGV[0] && $ARGV[0] =~ /^\d+$/;
print <<BANNER;
Listening on port $port. Specify another port as an argument, if needed.
Now, start your browser and go to this URL:

  http://localhost:8080/

BANNER

my $serv = lambda {
	context $server;
	accept {
		# incoming connection
		my $conn = shift;
		again;

		unless ( ref($conn)) {
			warn "accept() error:$conn\n" unless ref($conn);
			return;
		}
		$conn-> blocking(0);

		# try to read request - GET only
		my $buf     = '';
		my $session = {};
		context readbuf, $conn, \$buf, qr/^(.*?)\r\n\r\n/s, $conn_timeout;

	tail {
		my ( $match, $error) = @_;
		unless ( defined($match)) {
			warn "session error: $error\n";
			return close($conn);
		}

		# handle request
		substr( $buf, 0, length($match)) = '';
		my $req = HTTP::Request-> parse( $match);
		unless ( $req) {
			print $conn "bad request\r\n";
			return close($conn);
		}
	
		if ( lc($req-> protocol) ne 'http/1.1') {
			print $conn "404 HTTP/1.1 only\r\n";
			return close($conn);
		}

		again;

		# send response
		my $resp = handle( $req, $session)-> as_string;
		context writebuf, $conn, \$resp, length($resp), 0, $conn_timeout;
		&tail();
	}}
};

sub fail { HTTP::Response-> new( "HTTP/1.1 $_[0]", $_[1] ) }

sub handle
{
	my ( $req, $session) = @_;

	return fail(404, "GET request only")
		if $req-> method ne 'GET';

	$session-> {counter} ||= 0;
	if ( $req-> uri eq '/') {
	} elsif ( $req-> uri eq '/inc') {
		$session-> {counter}++;
	} elsif ( $req-> uri eq '/dec') {
		$session-> {counter}--;
	} elsif ( $req-> uri eq '/rst') {
		$session-> {counter} = 0;
	} else {
		fail( 404, "Not found");
	}
	
	my $content = <<CONTENT;
<html><body>
<h1>Counter: $session->{counter}</h1>
<p>
<a href="/inc">++</a><br>
<a href="/dec">--</a><br>
<a href="/rst">=0</a><br>
</body></html>

CONTENT
	return HTTP::Response-> new( 
		'HTTP/1.1 200', 'OK', [
			'Date'           => scalar(localtime),
			'Server'         => 'IO::Lambda',
			'Content-Type'   => 'text/html',
			'Content-Length' => length($content),
			'Connection'     => 'Keep-Alive',
			'Keep-Alive'     => $conn_timeout,
		], $content);
}

$serv-> wait;
