package TestHTTPReq;

use Module::Util qw(find_installed);
use HTTP::Date qw(time2str);
use HTTP::Status;
use HTTP::Response;
use HTTP::Daemon::Threaded::Content;
use base ('HTTP::Daemon::Threaded::Content');

use strict;
use warnings;

our $mtime = time2str((stat(find_installed(__PACKAGE__)))[9]);

sub new { my $class = shift; return $class->SUPER::new(@_); }

sub getContent {
	my ($self, $fd, $req, $uri, $params) = ($_[0], $_[1], $_[2], lc $_[3], $_[4]);

#print STDERR "Processing $uri\n";

#
#	trim possible leading slash
#
	$uri = substr($uri, 1)
		if (substr($uri, 0, 1) eq '/');

	return $fd->send_error(RC_NOT_FOUND)
		unless (($uri eq 'posted') || ($uri eq 'postxml'));

	my $html = "<html><body>\r\n";

	my $ct = 'text/html';
	if ($uri eq 'posted') {
#	print STDERR "posted params:", join(', ', sort keys %$params), "\n";
		$html .= "$_ is $$params{$_}<br>\r\n"
			foreach (sort keys %$params);
		$html .= "</body></html>";
	}
	else {
		$ct = 'text/xml';
#	print STDERR "posted content: $params \n";
		$html = $params;	# its the content
	}
	my $res = HTTP::Response->new(RC_OK, 'OK',
		[ 'Content-Type' => $ct,
			'Content-Length' => length($html),
			'Last-Modified' => $mtime
		]);
	$res->request($req);
	$res->content($html);
	return $fd->send_response($res);
}

sub getHeader {
	my ($self, $fd, $req, $uri, $params) = ($_[0], $_[1], $_[2], lc $_[3], $_[4]);

#print STDERR "Processing $uri\n";
#
#	trim possible leading slash
#
	$uri = substr($uri, 1)
		if (substr($uri, 0, 1) eq '/');

	return $fd->send_error(RC_NOT_FOUND)
		unless (($uri eq 'posted') || ($uri eq 'postxml'));

	my $html = "<html><body>\r\n";
	my $ct = 'text/html';
	if ($uri eq 'posted') {
		$html .= "$_ is $$params{$_}<br>\r\n"
			foreach (sort keys %$params);
		$html .= "</body></html>";
	}
	else {
		$ct = 'text/xml';
		$html = $params;	# its the content
	}
	my $res = HTTP::Response->new(RC_OK, 'OK',
		[ 'Content-Type' => $ct,
			'Content-Length' => length($html),
			'Last-Modified' => $mtime
		]);
	$res->request($req);
	return $fd->send_response($res);
}

1;

