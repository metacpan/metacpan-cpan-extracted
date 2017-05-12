# bad arguments test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

{
local $Plan = {'bad arguments' => 3} ;

throws_ok
	{
	eval <<'EOS' ;
		use Filter::Uncomment 
			GROUPS =>
				[
				multi  => ['multi_line', 'multi line with spaces'] ,
				single => ['single_line', 'single line with spaces'] ,
				all    => 
					[
					'multi_line', 'multi line with spaces',
					'single_line', 'single line with spaces',
					] ,
				];
EOS
	die $@ if $@ ;
	} qr/bad 'GROUPS'/, "group not a hash" ;

throws_ok
	{
	eval "use Filter::Uncomment 'GROUPS';" ;
	die $@ if $@ ;
	} qr/bad 'GROUPS'/, "group not a hash" ;


warning_like  
	{
	eval "use Filter::Uncomment ;" ;
	die $@ if $@ ;
	} qr/Filter::Uncomment needs arguments/, "need argument warning" ;
}

