use strict ;
use warnings ;
use Test ;

BEGIN {
	plan(tests => 2) ;
}

require "t/test.pm" ;

use Inline::Select::Register (
	PACKAGE => 'Calc',
	Inline => [ Perl => sub {require 't/Calc.pm'} ]
) ;
test('Perl') ;
