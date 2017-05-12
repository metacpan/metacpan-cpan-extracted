#!/usr/bin/env perl
use Moose;
use Test::More tests => 4;

{

    package MyClass;
    use Moose;
    with 'Dezi::Role';
}

ok( my $inst = MyClass->new, "new MyClass" );
is( $inst->warnings, 1, "warnings==1 default" );
is( $inst->debug,    0, "debug==0 default" );
is( $inst->verbose,  0, "verbose==0 default" );

