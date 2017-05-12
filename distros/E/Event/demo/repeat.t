#!./perl -w

use strict;
use Event;

# $Event::DebugLevel = 4;

my $w=Event->io(fd=>\*STDIN, repeat=>0, cb=>\&callback);

Event->timer(interval=>4, cb=>sub {
		 $w->repeat(!$w->repeat);
		 warn "repeat=".$w->repeat."\n";
		 state($w);
	     });

sub callback {
    my $w = $_[0]->w;
    my $h = $w->fd;
    my $in=<$h>;
    print "You entered: $in";
    if ($in =~ /start|again/) {
	$w->again;
    }
    state($w);
}

sub state {
    my ($w)=@_;
    warn 'Is: '.join(' ', $w->is_active?'ACTIVE':'INACTIVE', 
	      $w->is_suspended?'SUSP':'',
	      $w->is_cancelled?'CANCELLED':'')."\n";
}

print "
This demo shows the function of the repeat flag.  If you press return
while repeat=1 then the watcher will remain active.  If you press
return while repeat=0 then the watcher will become inactive.  If you
type 'again' while the watcher is inactive then again() will be called
in the callback and the watcher should continue to be active.

Granted, this is not very exciting.  :-)

";

Event::loop;
