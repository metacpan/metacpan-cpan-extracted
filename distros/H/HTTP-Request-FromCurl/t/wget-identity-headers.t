#!perl
use strict;
use HTTP::Request::FromWget;

use lib 't';
use TestWgetIdentity 'run_wget_tests';

my @tests = (
    { cmd => [ '-O', '-', '--debug', '--header', 'Host: example.com', '$url' ] },
    { name => 'Multiple headers',
      cmd => [ '-O', '-', '--debug', '--header', 'Host: example.com', '--header','X-Example: foo', '$url' ] },
    { name => 'Case-insensitive headers',
      cmd => [ '-O', '-', '--debug', '--header', 'accept: application/json', '--header','X-Example: foo', '$url' ] },
    { name => 'Duplicated header',
      cmd => [ '-O', '-', '--debug', '--header', 'X-Host: example.com', '--header','X-Host: www.example.com', '$url' ] },
    { cmd => [ '-O', '-', '--debug', , '--user-agent', 'www::mechanize/1.0', '$url' ],
    },
);

run_wget_tests( @tests );
