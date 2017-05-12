#!./perl -w

use Test; plan test => 1;
use Event qw(loop unloop sleep);
use Event::Stats;

$Event::DIED = sub {}; #ignore!

my $e;
$e = Event->idle(cb => sub {
		     sleep 1; 
		     die 'skip';
		 });
Event->timer(interval => .2, cb => sub {
		 my $e = shift;
		 unloop if ($e->w->stats(15))[0];
	     });

Event::Stats::collect(1);
loop;

ok join(',',$e->stats(15)), '/^0,\d,0/';
