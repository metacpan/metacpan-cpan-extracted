#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

get 'mangle' => sub {
    my $req = shift;

    return { -content => $req->get_url_full( override => 42, erase => undef ) };
};

is scalar neaf->run_test('/mangle')
    , 'http://localhost/mangle?override=42'
    , "No params";

is scalar neaf->run_test('/mangle?override=1&erase=2&extra=3')
    , 'http://localhost/mangle?extra=3&override=42'
    , "Params present";

is scalar neaf->run_test('/mangle', override =>
    { SERVER_PORT => 1337, SERVER_NAME => 3.1415})
    , 'http://3.1415:1337/mangle?override=42'
    , "No params, alter server";

done_testing;
