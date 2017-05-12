# test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Directory::Scratch::Structured qw(create_structured_tree) ; 

{
local $Plan = {'non OO interface' => 1} ;

throws_ok
	{
	create_structured_tree('file_0' => 'error') ;	
	} qr[\Qinvalid element './file_0' in tree structure], "bad argument caught" ;
}

