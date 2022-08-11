use strict;
use warnings;

use Test::More tests => 1;

use Net::Curl::Easy;
Net::Curl::Easy->can('CURLOPT_ACCEPT_ENCODING') or die "Rebuild Net::Curl with libcurl 7.21.6 or newer\n";

require_ok('HTTP::Curl');
