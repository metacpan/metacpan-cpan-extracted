#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf::Request;

my $req = MVC::Neaf::Request->new;

$req->set_cookie( foo => "bar", expire => 0 );

is_deeply( $req->format_cookies
    , [ 'foo=bar; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT' ]
    , "Cookie baked as expected" );

done_testing;

