# signal -*-perl-*-

BEGIN {
    if ($^O eq 'MSWin32') {
	print "1..0 # skipped; kill() doesn't send signals on Win32\n";
	exit;
    }
}

use Test; plan tests => 4;
use Event qw(loop unloop);

#$Event::DebugLevel = 3;

my $count = 3;

Event->signal(
    signal => 'USR1',
    cb =>
	sub {
	    my $e = shift;

	    ok $e->w->signal, 'USR1';
	    ok $e->hits > 0;  # threads can cause signal clumping

	    unloop;
	}
);

my $idle;
$idle = Event->idle(
    cb => sub {
	kill 'USR1',$$;
	kill 'USR1',$$;
	ok 1;
    }
);

loop;

ok 1;
