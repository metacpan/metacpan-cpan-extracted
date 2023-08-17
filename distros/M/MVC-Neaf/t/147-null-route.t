#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use MVC::Neaf::Request;

my $req = MVC::Neaf::Request->new;

lives_ok {
    my $route = $req->route;

    is $route->parent, undef, 'null route has no parent';
    throws_ok {
        $req->form('foobar');
    } qr/Failed.*form.*foobar.*/, 'no forms there';
    is $route->method, 'GET', 'GET by default';
    is $route->path, '[pre_route]', 'mangled empty path';
    throws_ok {
        $route->code->($req);
    } qr/^404/, 'not found stub inside';
} 'code doesn\'t explode';

done_testing;
