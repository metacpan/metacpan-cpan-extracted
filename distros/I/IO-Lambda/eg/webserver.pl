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
use IO::Lambda::HTTP::Server;

my $port = 8080;
$port = $ARGV[0] if $ARGV[0] && $ARGV[0] =~ /^\d+$/;

my ($serv,$error) = http_server { handle( @_ ) } "localhost:$port", timeout => 5;
die "Cannot create webserver: $error\n" unless $serv;

print <<BANNER;
Listening on port $port. Specify another port as an argument, if needed.
Now, start your browser and go to this URL:

  http://localhost:8080/

BANNER

my $conn_timeout = 10;

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
	} elsif ( $req-> uri eq '/stp') {
		$serv->shutdown;
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
<a href="/stp">exit</a><br>
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
