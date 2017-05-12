# load test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);
use Test::Cmd ;

{
local $Plan = {'options through -M' => 3} ;

my $test = Test::Cmd->new
		(
		prog => '',
		workdir => '',
		#~ verbose => 1,
		) ;
		
$test->run(interpreter => "perl -Mblib -MDebug::Mixin='Banner=should not be displayed' -e 42",)	;
unlike($test->stdout(), qr/Debug::Mixin loaded for 'should not be displayed'/, "no banner through -M when not debugging") ;

 
SKIP: 
	{
	skip "Can't automatize debugger yet", 1 ;

	$test->run
			(
			interpreter => "perl -d -Mblib -MDebug::Mixin='Banner=should be displayed' -e 42",
			stdin => "q\n",
			)	;
	like($test->stdout(), qr/Debug::Mixin loaded for 'should be displayed'/, "banner through -M") ;
	};

$test->run(interpreter => "perl -Mblib -MDebug::Mixin='LoadBreakpointsFiles=breakpoints_file_empty' -e 42",) ;
like($test->stdout(), qr/Loading 'breakpoints_file_empty'/, "LoadBreakpointsFiles through -M") ;

$test->cleanup() ;
}
