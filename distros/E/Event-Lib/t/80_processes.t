# Objective:
# ----------
#
# Make sure that events can be run in several
# processes simultaneously.
# Also, check that event_init is called for
# each process. At least on BSD-like systems,
# this should fail if Event::Lib has a problem
# with the way it handles event_init.

use Test;
use Event::Lib;
use IO::Handle;

BEGIN {
    plan tests => 5;
}

sub output {
    my $ev = shift;
    my $buf = readline $ev->fh;
    chomp $buf;
    if ($buf eq "done") {
	ok(1);
	$ev->remove;
	return;
    }
    ok($buf, "ok");
    Event::Lib::Debug::dump_pending_events;
}
	
pipe READER, WRITER;
READER->autoflush(1);
WRITER->autoflush(1);

my $pid = fork;

die if !defined $pid;

if ($pid) {
    # PARENT
    event_new(\*READER, EV_READ|EV_PERSIST, \&output)->add;
    event_mainloop;
    ok(1);
} else {
    # CHILD
    timer_new(sub { 
	print WRITER "ok\n"; 
	Event::Lib::Debug::dump_pending_events;
    })->add($_) for 1 .. 3;
    event_mainloop;
    sleep 1;
    print WRITER "done\n";
}
