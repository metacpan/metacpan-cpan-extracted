#!perl
use strict;
use HTTP::Request::FromWget;

use lib 't';
use TestWgetIdentity 'run_wget_tests';

my @tests = (
    { cmd => [ '-O', '-', '--debug', '--no-cache', '$url', '--header', 'X-Test: test' ],
        version => '001019003' # earlier versions sent "must-revalidate" as well
    },
    { cmd => [ '-O', '-', '--debug', '--no-cache', '--header', 'Cache-Control: must-revalidate', '$url', '--header', 'X-Test: test' ],
        version => '001019003' # earlier versions sent "must-revalidate" as well
    },
    { cmd => [ '-O', '-', '--debug', '--no-cache', '--header', 'Cache-Control: must-revalidate', '--header', 'Cache-Control: must-revalidate2', '$url', '--header', 'X-Test: test' ],
        version => '001019003' # earlier versions sent "must-revalidate" as well
    },
    { cmd => [ '-O', '-', '--debug', '--cache', '$url', '--header', 'X-Test: test' ] },
    { cmd => [ '-O', '-', '--debug', '--referer', 'https://referer.example.com', '$url' ] },
    { cmd => [ '-O', '-', '--debug', '-U', 'mywget/1.0', '$url' ] },
    { cmd => [ '-O', '-', '--debug', '--user-agent', 'mywget/1.0', '$url' ] },
    { cmd => [ '-O', '-', '--debug', '--post-file', '$tempfile', '$url' ] },
    { cmd => [ '-O', '-', '--debug', '--post-data', 'msg=hello%20world&from=wget', '$url' ] },
);

run_wget_tests( @tests );
