#!/usr/bin/perl
use strict;
use warnings;
no warnings 'redefine';
use Test::More;
use Data::Dumper;
use Try::Tiny;
use utf8;

use_ok( 'IRI' );
use_ok( 'URI' );

{
	my $base	= URI->new( 'http://example.org/ns/' );
	my $i		= IRI->new( value => 'foo/', base => $base );
	isa_ok($i, 'IRI');
	is($i->abs, 'http://example.org/ns/foo/');
}

done_testing();
