# test

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
local $Plan = {'help' => 1} ;

skip "unimplemented" => $Plan;

# run in debugger and jump to debugger when bp is active
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
