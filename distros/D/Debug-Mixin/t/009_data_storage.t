# data storage test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Debug::Mixin ; 

{
local $Plan = {'filters and actions run in eval blocks' => 1} ;

my $storage = '#storage#'  ;
my $storage_ref = \$storage;

Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'simple',
	ACTIONS => 
		[
		sub
			{
			my (%args) = @_ ;
			${$args{DEBUG_MIXIN_BREAKPOINT}{LOCAL_STORAGE}} .= '#action#' ;
			
			return(0) ;
			},
		],
	FILTERS =>
		[
		sub
			{
			my (%args) = @_ ;
			#~ use Data::TreeDumper ;
			#~ print DumpTree(\%args) ;
			
			${$args{DEBUG_MIXIN_BREAKPOINT}{LOCAL_STORAGE}} .= '#filter#' ;
			
			return(1) ; # so actions are run too
			},
		],
	ACTIVE => 1,
	LOCAL_STORAGE => $storage_ref,
	) ;

Debug::Mixin::CheckBreakpoints() ;

is($storage, '#storage##filter##action#', 'local storage passed around') ;

#cleanup
Debug::Mixin::RemoveAllBreakpoints() ;
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
