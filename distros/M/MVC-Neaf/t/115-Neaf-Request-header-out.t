#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf::Request;

my $req = MVC::Neaf::Request->new;

$req->set_header( x_foo => 42 );
is ( $req->header_out->as_string, "X-Foo: 42\n", "set header" );

$req->push_header( x_foo => 137 );
is ( $req->header_out->as_string, "X-Foo: 42\nX-Foo: 137\n", "add header" );

$req->set_header( x_foo => 451 );
is ( $req->header_out->as_string, "X-Foo: 451\n", "re-set header" );

$req->remove_header( "x_foo" );
is ( $req->header_out->as_string, "", "delete header" );

done_testing;
