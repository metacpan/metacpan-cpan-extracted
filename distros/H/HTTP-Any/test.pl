use strict;
use warnings;

use Test::More tests => 3;


SKIP: {
	eval {
		require Net::Curl::Easy;
		Net::Curl::Easy->can('CURLOPT_ACCEPT_ENCODING') or
		die "Rebuild Net::Curl with libcurl 7.21.6 or newer\n";
	};

	skip "Net::Curl::Easy: $@", 1 if $@;
	require_ok('HTTP::Any::Curl');
};

require_ok('HTTP::Any::AnyEvent');
require_ok('HTTP::Any::LWP');
