#!perl -T

use Test::More tests => 3;
use lib 't';

BEGIN {
	use_ok( 'Geo::Coder::Yahoo' );
}

diag( "Testing Geo::Coder::Yahoo $Geo::Coder::Yahoo::VERSION, Perl $], $^X" );

use Subclass;

ok($geo = Subclass->new, 'subclass');
ok($geo->isa("Subclass"), 'isa');

