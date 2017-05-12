#!/usr/bin/perl

use lib (
	'/home/jablko/perl/lib/perl/5.8.4/',
	'/home/jablko/perl/share/perl/5.8.4/'
);

use strict;
use warnings;

# Use POE::Component::Server::HTTP, or HTTP::Daemon
my $USE_PCSH = 0;

use Filesys::Virtual::DPAP;
use Net::DAV::Server::DPAP;

if ($USE_PCSH) {
	use POE;
	use POE::Component::Server::HTTP;
} else {
	use HTTP::Daemon;
}

my $DPAP_HOST = 'localhost';

my $fs = Filesys::Virtual::DPAP->new({
	host => $DPAP_HOST
});

my $dav = Net::DAV::Server::DPAP->new();
$dav->filesys($fs);

if ($USE_PCSH) {
	my $http = POE::Component::Server::HTTP->new(
		Port => 9080,
		ContentHandler => {
			'/' => \&handler
		}
	);

	sub handler {
		my ($request, $response) = @_;

		my $response1 = $dav->run($request, $response);

		# Lame attempts to copy $response1 -> $response. Bug #11848 is
		# better.
		#$response->code($response1->code);
		#$response->message($response1->message);
		#$response->headers($response1->headers);
		#$response1->scan({
		#	my ($name, $value) = @_;
		#	$response->header($name => $value);
		#});
		#for my $name ($response1->header_field_names) {
		#	$response->header($name => $response1->header($name));
		#}
		#$response->content($response1->content);

		return $response->code;
	}

	$poe_kernel->run;
} else {
	my $http = HTTP::Daemon->new(
		LocalPort => 9080,
		ReuseAddr => 1
	);

	while (my $connection = $http->accept) {
		while (my $request = $connection->get_request) {
			my $response = $dav->run($request);
			$connection->send_response($response);
		}
		$connection->close;
	}
}
