#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf qw(:sugar);

neaf form => food => {
    type     => [ required => '\w+'],
    quantity => '\d+',
    tasty    => '[yn]',
};

my $capture;

neaf pre_route => sub { undef $capture };
get '/eatme' => sub {
    my $req = shift;
    $capture = $req->form("food");
    return { -content => $capture->is_valid ? 'Gotcha' : 'Stop' };
};

# now do testing

is neaf->run_test( '/eatme?quantity=42&tasty=y' ), 'Stop', "Controller ok";
ok !$capture->is_valid, "Type missing";
is_deeply [keys %{ $capture->error }], ["type"], "proper error";
note explain $capture->error;

is neaf->run_test( '/eatme?type=sausage&tasty=y' ), 'Gotcha', "Controller ok";

done_testing;
