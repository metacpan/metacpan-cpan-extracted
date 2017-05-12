# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use strict ;
use Test ;
use ExtUtils::MakeMaker ;
BEGIN { 
	my $oldfh = select STDERR ;
	my $ans = prompt("\nDo you wish to execute the interactive tests?", 'n') ;
	select $oldfh ;
	if ($ans !~ /^y/i){
		plan(
			tests => 0,
		) ;
		exit ;
	}
	else {
		plan (
			tests => 1,
		) ;
	}
} ;

use Event::SlidingWindow ;

#########################

print STDERR <<TXT;

You will now play a boxing match against me. To hit me you must press the 
ENTER key. If you hit me more than 5 times within 5 seconds you will win 
and the test will be over. If you hit me at a lower rate I will be able to 
continue.
TXT

my $esw = new Event::SlidingWindow(5) ;
while (1){
	my $n = $esw->count_events() ;
	if ($n > 5){
		print STDERR "Knock Out!!!\n" ;
		ok(1) ;
		exit ;
	}
	
	print STDERR "Hit me when you're ready (" ;
	# print STDERR "$n hits within the last 5 seconds" ;
	print STDERR join("-", @{$esw->_dump()}) ;
	print STDERR "): " ;
	<STDIN> ;
	$esw->record_event() ;
}
