
use Test::Simple tests => 3;

use Math::CatmullRom;

my ( $o, @p, @ep, @np );

@p = ( 50, 50, 50, 600, 300, 600, 800, 800 );

@ep = ( 50, 50, 50, 600, 300, 600, 800 );

@np = ();

eval
{
	$o = new Math::CatmullRom( @p );
};

ok( ( not $@ ), 'new good data' );

eval
{
	$o = new Math::CatmullRom( @ep );
};

ok( $@, 'new short data' );

eval
{
	$o = new Math::CatmullRom( @np );
};

ok( $@, 'new null data' );

exit;
