#!perl
use strict;
use HTTP::Request::FromCurl;

use lib 't';
use TestCurlIdentity 'run_curl_tests';

my @tests = (
    { name => 'Form parameters',
      ignore => [ 'Content-Length', 'Content-Type' ],
      cmd => [ '--verbose', '-g', '-s', '$url', '--get', '-F', 'name=Foo', '-F','version=1' ],
      version => '007061000', # earlier versions send an Expect: 100-continue header
      },
    { name => 'Append GET data',
      cmd => [ '--verbose', '-g', '-s', '$url', '--get', '-d', '{name:cool_event}' ] },
    { name => 'Append GET data to existing query',
      cmd => [ '--verbose', '-g', '-s', '$url?foo=bar', '--get', '-d', '{name:cool_event}' ] },
    { cmd => [ '--verbose', '-g', '-s', '$url', '-d', '{name:cool_event}' ] },
    { cmd => [ '--verbose', '-g', '-s', '--data-binary', '@$tempfile', '$url' ] },
    # perlmonks post xxx
    { cmd => [ '--verbose', '-s', '-g',
               '-X', 'POST',
               '-u', "apikey:xxx",
               '--header', "Content-Type: audio/flac",
               '--data-binary', '@$tempfile', '$url' ], },
);

run_curl_tests( @tests );
