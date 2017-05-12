#!./perl -w
#
# Test script to check the memory consumption
# of an Event loop which installs, handles and
# cancels a number of IO watchers (recursively).
#
# For extra diagnostics, Event.pm can be built with
# -DEVENT_MEMORY_DEBUG.
#
# If the script succeeds, the final memory check
# replies something like this:
# "1-29509-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0"
# (all slots except of the first two ones should
# be 0 - the second number may differ).
#
# J. Stenzel (perl@jochen-stenzel.de)
#

use Test; plan test => 2;

use Event;
# $Event::DebugLevel = 3;

sub check {warn "[DBG] ", join('-', Event::_memory_counters), "\n";}

sub iosub {
    for (my $l=0; $l<=5; $l++) {
	Event->io(
		  fh => \*STDIO, timeout => "0.5$l",
		  repeat => 1, cb => \&iosub,
		  prio => 5);
    }
    $_[0]->w->cancel;
}

Event->io(fh => \*STDIO, timeout => 0.5, repeat => 1,
	  cb => \&iosub, prio => 5);

Event->timer(prio => 1, after => 3,
	     cb => sub {
		 $_->cancel foreach Event::all_watchers;
		 ok !defined Event::all_watchers;
	     }
	    );

Event::loop();
ok 1;
