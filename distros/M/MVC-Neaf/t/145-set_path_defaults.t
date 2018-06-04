#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

my $n = MVC::Neaf->new;

$n->set_path_defaults( { global => 'global' } );
$n->set_path_defaults( { local => 'not seen' } );
$n->set_path_defaults( { local => 'in foo' }, path => '/foo' );
$n->set_path_defaults( { local => 'in bar' }, path => '/foo/bar' );

is $n->get_path_defaults( 'GET', '/foo' )->{global}, 'global', "Global value as is";
is $n->get_path_defaults( 'GET', '/foo' )->{local}, 'in foo', "Local value overridden";
is $n->get_path_defaults( 'GET', '/foo' )->{-status}, 200, "Hardcoded status = 200 OK";

done_testing;
