# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use strict ;
use Test ;
BEGIN { 
	plan(
		tests => 3,
	) ;
} ;

use Event::SlidingWindow ;
ok(1) ;

#########################

print STDERR "\nThese tests use sleep() so please be patient...\n" ;
my $esw = new Event::SlidingWindow(3, 1) ;
$esw->record_event() ;
$esw->record_event() ;
$esw->record_event() ;
$esw->record_event() ;
$esw->record_event() ;
ok($esw->count_events(), 5) ;

sleep(5) ;
ok($esw->count_events(), 0) ;
