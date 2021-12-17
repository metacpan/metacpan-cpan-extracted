#!perl
use strict;
use HTTP::Request::FromCurl;

use lib 't';
use TestCurlIdentity 'run_curl_tests';

my @tests = (
    { cmd => [ '--verbose', '-g', '-s', '-H', 'Host: example.com', '$url' ] },
    { name => 'Multiple headers',
      cmd => [ '--verbose', '-g', '-s', '-H', 'Host: example.com', '-H','X-Example: foo', '$url' ] },
    { name => 'Duplicated header',
      cmd => [ '--verbose', '-g', '-s', '-H', 'X-Host: example.com', '-H','X-Host: www.example.com', '$url' ] },
    { name => 'Lower-case header',
      cmd => [ '--verbose', '-g', '-s', '-H', 'accept: application/json', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '--oauth2-bearer','someWeirdStuff', '$url' ],
      version => '007061000',
    },
    { cmd => [ '--verbose', '-g', '-s', '--user-agent', 'www::mechanize/1.0', '$url' ],
    },
    { cmd => [ '--verbose', '-s', '-g', '$url', '--header', 'X-Test: test' ] },
);

run_curl_tests( @tests );
