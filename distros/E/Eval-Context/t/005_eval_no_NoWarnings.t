# test

use strict ;
use warnings ;

use Data::TreeDumper ;

use Test::Exception ;
use Test::Warn;
#~ use Test::NoWarnings qw(had_no_warnings);

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Eval::Context ; 

{
local $Plan = {'No NoWarnings' => 2} ;
	
# the Test::NoWarnings module makes the following test segfault!! Test without that module
	
my $context = new Eval::Context() ;

lives_ok
	{
	my $value = $context->eval(CODE => "(7,8) ;", PACKAGE => 'A') ;
	is($value, 8, 'eval returned last value') or diag "latest code:\n$context->{LATEST_CODE}\n" ;
	} 'returned list, scalar context' ;
}
