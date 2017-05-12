#!./perl -w

use strict;
use Test; plan test => 6;
use Event qw(time);
require Event::group;

my $g = Event->group(parked=>1, timeout => 1.95, cb => sub {
			 my $e = shift;
			 warn "timeout at ".$e->w->cbtime;
		     },
		     add => Event->timer(desc => '1', interval => 2,
					 cb => sub {
					     my $e = shift;
					     warn "boink #1 at ".$e->w->cbtime
					 }),
		     add => Event->timer(desc => '2', interval => 2.5,
					 cb => sub {
					     my $e = shift;
					     warn "boink #2 at ".$e->w->cbtime
					 }),
		    );
$g->start;

Event::loop();
