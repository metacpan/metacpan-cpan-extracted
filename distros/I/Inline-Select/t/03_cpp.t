use strict ;
use warnings ;
use Test ;

BEGIN {
	eval { require Inline::CPP } ;
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
	Inline => [ CPP => 't/Calc.cpp' ]
) ;
test('CPP') ;
