# output test

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
local $Plan = {'output' => 1} ;

skip "unimplemented" => $Plan;

#output is indented
# output from BP is captured
# output history is kept
# call stack information is kept
# output can be directed to log4P
# output is colorized
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
