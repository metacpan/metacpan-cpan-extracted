#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

neaf form => fu => [ [ 'term\d+' => '\d+' ] ], engine => 'Wildcard';

my $capture;
neaf pre_route => sub { undef $capture };
get '/bar' => sub {
    my $req = shift;

    $capture = $req->form("fu");

    return { -content => 'Gotcha' };
};

neaf->run_test( '/bar?term1=pi&term2=3.14&term3=4&therm4=3' );

is_deeply $capture->data, { term3 => 4 }
    , "Perhaps we're in Indiana - pi == 4 works";

ok !$capture->raw->{therm4}, "No matching key = not got anywhere";

done_testing;

