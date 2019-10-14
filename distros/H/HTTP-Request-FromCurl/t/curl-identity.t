#!perl
use strict;
use HTTP::Request::FromCurl;

use lib 't';
use TestCurlIdentity 'run_curl_tests';

my @tests = (
    { cmd => [ '--verbose', '-g', '-s', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '-X', 'PATCH', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '-XPATCH', '$url' ],
      name => 'short bundling options' },
    { cmd => [ '--verbose', '-g', '-s', '--head', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '-i', '$url' ],
      name => 'ignore --include option' },
    { cmd => [ '--verbose', '-s', '-g', '$url', '--request', 'TEST' ] },
);

run_curl_tests( @tests );
