#!perl
#!perl
use strict;
use Test::More;
use HTTP::Request::FromCurl;
use Data::Dumper;

#use lib 't';
#use TestCurlIdentity 'run_curl_tests', '$server';

my @tests = (
    { cmd => [ '--verbose', '-s', '$url', '$url?foo=bar', ] },
    { cmd => [ '--verbose', '-s', '$url?foo={bar,baz}', ] },
    { cmd => [ '--verbose', '-s', '-g', '$url', '$url?foo={bar,baz}', ] },
    { cmd => [ '--verbose', '-s', '--globoff', '$url', '$url?foo={bar,baz}', ] },
);

plan tests => 0+@tests;

for my $test (@tests) {
    my @r = HTTP::Request::FromCurl->new( argv => $test->{cmd} );

    is 0+@r, 2, "We recognize the expected number of requests";
};

done_testing;
