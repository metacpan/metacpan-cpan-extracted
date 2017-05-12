# banner test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

#~ use Test::Output;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Test::Cmd ;

{
local $Plan = {'banner displayed' => 2} ;

my $test = Test::Cmd->new
		(
		workdir => '',
		#verbose => 1,
		prog => '004_1_banner'
		) ;

$test->write('004_1_banner', <<EOS)	;

use Debug::Mixin
		{
		BANNER => '004_1_banner'
		} ;
	
print "running " . __FILE__ . "\n" ;

EOS

$test->run(interpreter => 'perl', prog => $test ->workdir() .'/' . '004_1_banner')	;
unlike($test->stdout(), qr/Debug::Mixin loaded for '004_1_banner'/, "no banner when not debugging") ;

SKIP: 
	{
	skip "Can't automatize debugger yet", 1 ;
	$test->run(interpreter => 'perl -d', prog => $test ->workdir() .'/' . '004_1_banner')	;
	like($test->stdout(), qr/Debug::Mixin loaded for '004_1_banner'/, "banner when debugging") ;
	}

$test->cleanup() ;
}
