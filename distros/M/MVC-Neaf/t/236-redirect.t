#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

get '/' => sub {
    my $req = shift;
    $req->redirect( "/foobar" );
};

my ($status, $head, $body) = neaf->run_test("/");

is $status, 302, "302 Found status";
is $head->header("Location"), '/foobar', "Location specified";
like $body, qr#/foobar#, "Link in body, too";

note $body;

done_testing;
