#!perl
use strict;
use HTTP::Request::FromWget;

use lib 't';
use TestWgetIdentity 'run_wget_tests';

my @tests = (
    #{ cmd => [ '--verbose', '-g', '-s', '$url', '--max-time', 5 ] },
    { cmd => [ '-O', '-', '--debug', '--http-keep-alive', '$url', '--header', 'X-Test: test' ] },
    { cmd => [ '-O', '-', '--debug', '--no-http-keep-alive', '$url', '--header', 'X-Test: test' ] },
    { cmd => [ '-O', '-', '--debug', '--no-check-certificate', '$url' ] },
    #{ cmd => [ '--verbose', '-g', '-s', '$url', '--buffer' ] },
    #{ cmd => [ '--verbose', '-g', '-s', '$url', '--show-error' ] },

    # This is not entirely correct - later releases of wget might be built
    # without zlib and thus not support --compression either
    { cmd => [ '-O', '-', '--debug', '--compression', 'auto', '$url', '--header', 'X-Test: test' ],
        version => 1019003,
        todo => 'Versions of Wget beyond 1.19.3 must be built with zlib to support --compression',
    },
    { cmd => [ '-O', '-', '--debug', '--compression', 'gzip', '$url', '--header', 'X-Test: test' ],
        version => 1019003,
        todo => 'Versions of Wget beyond 1.19.3 must be built with zlib to support --compression',
    },
    { cmd => [ '-O', '-', '--debug', '--compression', 'none', '$url', '--header', 'X-Test: test' ],
        version => 1019003,
        todo => 'Versions of Wget beyond 1.19.3 must be built with zlib to support --compression',
    },
    { cmd => [ '-O', '-', '--debug', '--method', 'PUT', '$url', '--body-data', '{}' ],
        version => 1015000,
    },
    { cmd => [ '-O', '-', '--debug', '--timeout', '99', '$url' ],
    },
    { cmd => [ '-O', '-', '--debug', '--bind-address', '$host', '$url' ],
    },
);

run_wget_tests( @tests );
