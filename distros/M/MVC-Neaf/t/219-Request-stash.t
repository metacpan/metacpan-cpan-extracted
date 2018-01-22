#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf qw(:sugar);

get '/foo' => sub {
    my $req = shift;
    return { -content => $req->stash->{plain} };
};

neaf pre_logic => sub {
    my $req = shift;
    $req->stash(unused => 100500)->stash( plain => 42 );
};

is scalar neaf->run_test( "/foo" ), 42, "Content round trip";

done_testing;
