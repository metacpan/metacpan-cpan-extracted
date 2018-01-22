#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf qw(:sugar);

del '/foo' => sub { +{ -content => $_[0]->method} };
any[ 'put', 'patch' ]=> '/bar' => sub { +{ -content => $_[0]->method} };

like scalar neaf->run_test( '/foo' ), qr/405/, "Wrong method => 405";
is   scalar neaf->run_test( '/foo', method => 'DELETE' ), 'DELETE'
    , "Method ok (del)";
is   scalar neaf->run_test( '/bar', method => 'PUT' ), 'PUT', "Method ok (any)";


done_testing;
