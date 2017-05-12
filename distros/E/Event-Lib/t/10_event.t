use Test;
BEGIN { plan tests => 2 }
use Event::Lib;
use Socket;

use warnings;

ok(1); 

pipe READER, WRITER;

my $pid = fork;
skip($!, 1), exit if not defined $pid;

if ($pid) {
    # PARENT
    event_priority_init(10);	# should never give an error, regardless of libevent version
    my $event = event_new(\*READER, EV_READ|EV_PERSIST, 
	sub {  
	    my $ev = shift;
	    my $fh = $ev->fh;
	    read ($fh, my $buf, 2);
	    if ($buf eq 'ok') {
		ok(1);
	    }
	    exit;
	}
    );
    $event->add;
    event_one_loop(10);
    ok(0);
} else {
    # CHILD
    $| = 1;
    print WRITER "ok\n";
    exit;
}


