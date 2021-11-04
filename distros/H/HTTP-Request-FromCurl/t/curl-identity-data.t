#!perl
use strict;
use HTTP::Request::FromCurl;

use lib 't';
use TestCurlIdentity 'run_curl_tests';

# For testing whether our test suite copes with %20 vs. + well:
#$URI::Escape::escapes{" "} = '+';

my @tests = (
    { cmd => [ '--verbose', '-g', '-s', '--data', '@$tempfile', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '--data-ascii', '@$tempfile', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '--data-binary', '@$tempfile', '$url' ],
      version => 7002000 },
    { cmd => [ '--verbose', '-g', '-s', '--data-raw', '@$tempfile', '$url' ],
      version => 7043000 },
    { cmd => [ '--verbose', '-g', '-s', '--data-urlencode', '@$tempfile', '$url' ],
      version => 7018000 },
);

run_curl_tests( @tests );
