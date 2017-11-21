#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf qw(:sugar);

my $capture; # for capture

get+post '/' => sub {
    $capture = shift;
    return { -content => 'pwned' };
};

neaf->run_test( '/', method => 'POST', body => 'life=42&fine=137', type => '?' );
# note explain $capture;

is ($capture->body, 'life=42&fine=137', "body round trip");
is $capture->scheme, 'http', "non secure";

neaf->run_test( '/', cookie => { foo => 42, bar => 137 }, secure => 1 );

is $capture->get_cookie( foo => '\d+' ), 42, "Cookie hash ok";
is $capture->get_cookie( bar => '\d+' ), 137, "Cookie hash ok (2)";
is $capture->scheme, 'https', "secure";

done_testing;
