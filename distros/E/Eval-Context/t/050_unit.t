
use strict ;
use warnings ;

use Data::TreeDumper ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings qw(had_no_warnings);

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Eval::Context ; 

{
local $Plan = {'CanonizeName' => 3} ;

throws_ok
	{
	Eval::Context::CanonizeName() ;
	} qr/CanonizeName called with undefined argument/, 'invalid input' ;
	
my $uncanonized = '1/;[-|-(_ ' ;
my $canonized = Eval::Context::CanonizeName($uncanonized) ;
is($canonized, '1_________', 'canonized') ;
is(length($canonized), length($uncanonized), 'right length') ;
}
