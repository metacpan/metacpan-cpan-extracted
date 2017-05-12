#!/usr/bin/perl

use Test::More 'no_plan';

my $class  = 'Distribution::Cooker';
my $module = 'Foo::Bar';
my $dist   = 'Foo-Bar';

use_ok( $class );
can_ok( $class, 'module_to_distname' );

my $cooker = $class->new;
isa_ok( $cooker, $class );
can_ok( $cooker, 'module_to_distname' );

is( $cooker->module_to_distname( $module ), 
	$dist, 
	"module_to_distname translates :: to -"  
	);
