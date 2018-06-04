#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

# BEGIN APP
neaf session => 'MVC::Neaf::X::Session::Cookie', key => 'very secret key';
neaf default => {-view => 'JS'};

get login => sub {
    my $req = shift;

    $req->save_session({ name => $req->param( name => '\w+' ) });
    return {};
};

get check => sub {
    my $req = shift;

    return $req->session;
};
# END APP

is scalar neaf->run_test( '/check' ), '{}', "empty /check";

my ($status, $head, $content) = neaf->run_test( '/login?name=Foo' );

my $cook = $head->header( 'Set-Cookie' );

note $cook;

$cook =~ /(.*?);/;
is scalar neaf->run_test( '/check', cookie => $1 ), '{"name":"Foo"}'
    , "named /check";

done_testing;
