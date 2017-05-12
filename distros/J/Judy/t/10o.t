#!perl
use strict;
use warnings;
use Test::More tests => 15;
use Judy::1 qw( Set Unset Test Free );

{
    my $judy;
   
    {
	my $val = Test( $judy, 42 );
	ok( !$judy, q(Judy doesn't exist until added to) );
	ok( !$val, q(Can't fetch values from nonexistant Judy) );
    }

    {
	my $val = Set( $judy, 42 );
	ok( $judy, 'Judy is true' );
        ok( $val, 'Toggled 42' );
	is( Test( $judy, 42 ), 1, 'Setting judy[42]' );
    }

    {
	my $val = Set( $judy, 42 );
        ok( !$val, 'Already toggled 42' );

	$val = Test( $judy, 42 );
        ok( $val, 'Fetched judy[42]' );
    }

    {
	my $deleted = Unset( $judy, 42 );
	ok( $deleted, 'Unsetd judy[42]' );
    }
    
    {
    	my $val = Test( $judy, 17 );
    	ok( !$val, 'Fetched nothing value for deleted things' );
    }

    {
    	my $deleted = Unset( $judy, 42 );
    	ok( !$deleted, q(Can't delete judy[42] because it was already deleted) );
    }

    {
	my $val = Test( $judy, 17 );
	ok( !$val, 'Fetched 0 value for deleted things' );

	my $deleted = Unset( $judy, 17 );
	ok( !$deleted, q(Can't delete things that haven't been added) );
    }

    {
	my $freed = Free( $judy );
	is( $judy, 0, 'Judy is free' );
    }

    {
        Set( $judy, 13 );
	my $freed = Free( $judy );
        diag( "Freed $freed bytes" );
	is( $judy, 0, 'Judy is free' );
	isnt( $freed, 0, 'Judy freed something' );
    }
}
