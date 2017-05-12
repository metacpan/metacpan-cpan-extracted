# query test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Debug::Mixin ; 

SKIP: 
{
local $Plan = {'query' => 1} ;

skip "unimplemented" => $Plan;

# get list of all using module
# get list of all calling BP
# get list of all fired BP
# get dump

# loading breakpoints is possible at debug time
}

=comment

{
local $Plan = {'' => } ;

is(result, expected, "message") ;
dies_ok
	{
	
	} "" ;

lives_ok
	{
	
	} "" ;

like(result, qr//, '') ;

warning_like
	{
	} qr//i, "";

is_deeply
	(
	generated,
	[],
	'expected values'
	) ;

}

=cut
