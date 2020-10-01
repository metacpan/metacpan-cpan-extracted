#!perl
use strict;
use HTTP::Request::FromCurl;

use lib 't';
use TestCurlIdentity 'run_curl_tests';

my @tests = (
    { cmd => [ '--verbose', '-g', '-s', '--data', '@$tempfile', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '--data-ascii', '@$tempfile', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '--data-binary', '@$tempfile', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '--data-raw', '@$tempfile', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '--data-urlencode', '@$tempfile', '$url' ] },
);

run_curl_tests( @tests );
