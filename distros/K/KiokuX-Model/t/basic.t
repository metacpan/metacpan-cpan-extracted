#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'KiokuX::Model';

my $m = KiokuX::Model->connect("hash");

isa_ok( $m, "KiokuX::Model" );

is( $m->dsn, "hash" );

can_ok( $m, qw(
	lookup

	store
	update
	insert

	clear_live_objects
) );

isa_ok( $m->directory, "KiokuDB" );
