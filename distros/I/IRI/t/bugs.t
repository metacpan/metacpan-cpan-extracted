#!/usr/bin/perl
use strict;
use warnings;
no warnings 'redefine';
use Test::More;
use Data::Dumper;
use Try::Tiny;
use utf8;

use_ok( 'IRI' );

{
	my $i;
	try {
		$i	= IRI->new(value => 'http://www.xn--orfolkedansere-rqb.dk/#8835/St%C3%A6vne%202013');
	} catch {
		diag $_;
	};
	isa_ok($i, 'IRI');
}

{
	my $base	= IRI->new( value => 'http://a.example/' );
	my $i		= IRI->new( value => 's', base => $base );
	isa_ok($i, 'IRI');
	is($i->abs, 'http://a.example/s');
}

{
	my $base	= IRI->new( value => 'http://a.example/' );
	my $i		= IRI->new( value => '#', base => $base );
	isa_ok($i, 'IRI');
	is($i->abs, 'http://a.example/#');
}

{
	my $base	= IRI->new( value => 'http://example.org/ns/' );
	my $i		= IRI->new( value => 'foo/', base => $base );
	isa_ok($i, 'IRI');
	is($i->abs, 'http://example.org/ns/foo/');
}

{
	my $i		= IRI->new( value => 'file:///Users/eve/data/bob.rdf' );
	isa_ok($i, 'IRI');
	is($i->abs, 'file:///Users/eve/data/bob.rdf');
}

{
	my $base	= IRI->new( value => 'file:///Users/eve/data/bob.rdf' );
	my $i		= IRI->new( value => '', base => $base );
	isa_ok($i, 'IRI');
	is($i->abs, 'file:///Users/eve/data/bob.rdf');
}

done_testing();
