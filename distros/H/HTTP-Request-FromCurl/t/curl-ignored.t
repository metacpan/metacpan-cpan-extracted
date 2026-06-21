#!perl
use strict;
use HTTP::Request::FromCurl;

use lib 't';
use TestCurlIdentity 'run_curl_tests';

my @tests = (
    { cmd => [ '--verbose', '-g', '-s', '--show-error', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '--silent', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '--anyauth', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '--disable', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '--dump-header','-', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '--follow', '$url' ]
        , version => '8016000' },
    { cmd => [ '--verbose', '-g', '-s', '--include', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '--location', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '--progress-bar', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '--parallel', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '--parallel-immediate', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '--parallel-max', '9', '$url' ] },
    { cmd => [ '--verbose', '-g', '-s', '--junk-session-cookies', '$url' ] },
);

run_curl_tests( @tests );
