# Objective:
# ----------
#
# Make sure that 
#
#   $ev->add(0) == $ev->add != $ev->add(0.0)

use Test;
BEGIN { plan tests => 4 }
use Event::Lib;
use Socket;
use warnings;

ok(1); 

pipe READER, WRITER;

my $pid = fork;
skip($!, 1), exit if not defined $pid;

if ($pid) {
    # PARENT
    event_new(\*READER, EV_READ|EV_PERSIST, 
	sub {  
	    my ($ev, $type) = @_;
	    ok($type, EV_READ);
	    read ($ev->fh, my $buf, 2);
	    if ($buf eq 'ok') {
		ok(1);
	    }
	}
    )->add(0);
    event_one_loop(10);
    event_new(\*READER, EV_READ|EV_PERSIST, 
	sub {  
	    my ($ev, $type) = @_;
	    ok($type, EV_TIMEOUT);
	    exit;
	}
    )->add(0.0);
    event_one_loop(10);
    wait;
} else {
    # CHILD
    $| = 1;
    sleep 1;
    print WRITER "ok\n";
    exit;
}


