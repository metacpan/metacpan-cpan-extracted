use strict ;
use warnings ;
use Test ;

BEGIN {
    eval { require Inline::Python } ;
	if ($@){
		plan(tests => 0) ;
		exit() ;
	}
	else {
		plan(tests => 2) ;
	}
}

require "t/test.pm" ;


use Inline::Select::Register (
	PACKAGE => 'Calc',
	Inline => [ Python => 't/Calc.py' ]
) ;
test('Python') ;
