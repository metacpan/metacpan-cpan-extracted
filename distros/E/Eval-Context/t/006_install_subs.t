# test

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
local $Plan = {'install subs' => 2} ;

{
my $get_117 = sub{117} ;
my $result = new Eval::Context(PACKAGE => 'TEST')->eval(CODE => 'get_117() ;', INSTALL_SUBS => {get_117 => $get_117}) ;

is($result, 117, 'sub pushed into context') ;
}
	
throws_ok
	{
	my $context = new Eval::Context(INSTALL_SUBS => {get_117 => 'error'})->eval(CODE => '') ;
	} qr/'get_117' from 'INSTALL_SUBS' isn't a code reference/, 'is not a code reference' ;
}
