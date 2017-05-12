# idle daydreams -*-perl-*-

# This test is too sensitive to slight variations in timing
# to serve as part of the test suite.

BEGIN {
    eval {
	require Time::HiRes;
	Time::HiRes->VERSION(1.20);
    };
    if ($@) {
	print "1..0\n";
	print "ok 1 # skipped; requires Time::HiRes 1.20\n";
	exit;
    }
}

use Test; plan tests => 5;
use Event qw(loop unloop time all_events one_event);

# $Event::Eval = 1;
# $Event::DebugLevel = 4;
$Event::DIED = \&Event::verbose_exception_handler;

#----------- complex idle events; fuzzy timers

my ($cnt,$min,$max,$sum) = (0)x4;
my $prev;
$min = 100;
my $Min = .01;
my $Max = .2;
Event->idle(min => $Min, max => $Max, desc => "*IDLE*TEST*",
	    cb => sub {
		my $now = time;
		if (!$prev) { $prev = time; return }
		my $d = $now - $prev;
		$prev = $now;
		$sum += $d;
		$min = $d if $d < $min;
		$max = $d if $d > $max;
		unloop('done') if ++$cnt > 10;
	    });
my $sleeps=0;
Event->idle(repeat => 1, cb => sub { Event::sleep $Min; ++$sleeps });

Event::sleep .1; # try to let CPU settle
loop();

my $epsilon = .05;
ok $sleeps > 1; #did we test anything?
ok $min >= $Min-$epsilon;
ok $max < $Max+$epsilon;   # fails without high resolution clock XXX
ok $sum/$cnt >= $min;
ok $sum/$cnt <= $max;
