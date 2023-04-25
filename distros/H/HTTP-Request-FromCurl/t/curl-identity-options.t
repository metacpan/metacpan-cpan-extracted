#!perl
use strict;
use HTTP::Request::FromCurl;

use lib 't';
use TestCurlIdentity 'run_curl_tests';

my @tests = (
    { cmd => [ '--verbose', '-g', '-s', '$url', '--max-time', 5 ] },
    { cmd => [ '--verbose', '-g', '-s', '$url', '--keepalive' ] },
    { cmd => [ '--verbose', '-g', '-s', '$url', '--no-keepalive' ] },
    { cmd => [ '--verbose', '-g', '-s', '$url', '--buffer' ] },
    { cmd => [ '--verbose', '-g', '-s', '$url', '--show-error' ] },
    { cmd => [ '--verbose', '-g', '-s', '$url', '-S' ] },
    { cmd => [ '--verbose', '-s', '-g', '--compressed', '$url' ],
      ignore => ['Accept-Encoding'], # this somewhat defeats this test but at least
      # we check we don't crash. Available compressions might differ between
      # Curl and Compress::Zlib, so ...
    },
    { cmd => [ '--verbose', '-Z', '-s', '$url', '-S' ],
      version => '007068000',
    },
    { cmd => [ '--verbose', '--parallel', '-s', '$url', '-S' ],
      version => '007068000',
    },
);

run_curl_tests( @tests );
