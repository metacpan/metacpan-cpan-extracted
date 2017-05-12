#!/usr/bin/perl

use Test::More 'no_plan';

my $class  = 'Distribution::Cooker';
my $module = 'Foo::Bar';

use_ok( $class );
can_ok( $class, 'init' );

my $cooker = $class->new;
isa_ok( $cooker, $class );

ok( $cooker->init, "init returns true" );