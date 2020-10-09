#!perl
#!perl
use strict;
use Test::More;
use HTTP::Request::FromCurl;

use lib 't';
use TestCurlIdentity 'run_curl_tests', '$server';

my @tests = (
    { cmd => [ '--verbose', '-s', '$url', '$url?foo=bar', ],
      ignore_headers => 'Cookie', # Curl handling of these is inconsistent
    },
    { cmd => [ '--verbose', '-s', '$url', '--junk-session-cookies', '$url?foo=bar', ],
      ignore_headers => 'Cookie', # Curl handling of these is inconsistent
    },
    { cmd => [ '--verbose', '-s', '$url', '--next', '$url?foo=bar', ],
      version => 7036000,
      ignore_headers => 'Cookie', # Curl handling of these is inconsistent
    },
    { cmd => [ '--verbose', '-s', '$url', '-:', '$url?foo=bar', ],
      version => 7036000,
      ignore_headers => 'Cookie', # Curl handling of these is inconsistent
    },
    { cmd => [ '--verbose', '-s', '$url?foo={bar,baz}', ],
      ignore_headers => 'Cookie', # Curl handling of these is inconsistent
    },
    { cmd => [ '--verbose', '-s', '-g', '$url', '$url?foo={bar,baz}', ],
      ignore_headers => 'Cookie', # Curl handling of these is inconsistent
    },
    { cmd => [ '--verbose', '-s', '--globoff', '$url', '$url?foo={bar,baz}', ],
      ignore_headers => 'Cookie', # Curl handling of these is inconsistent
    },
);

run_curl_tests( @tests, 14*@tests );
