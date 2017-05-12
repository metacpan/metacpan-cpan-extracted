# Yet another memory leak test.
# This is to make sure that registering a new event with the
# same handler as the currently executing one doesn't leak.
# This leak manifested itself through this $counter-hack:
#
# my $counter = 0;
# sub _handle_event {
#   my ($e, $evtype, $io_event, $self);
#   if ($counter++ % 300) {
#	$e->add(0.0000001);
#   } else {
#	$io_event->add(0.0000001);
#   }
# }

# XXX This test does NOT work with Test::More as
# XXX that will apparently allocate more and more 
# XXX memory.

use constant HAS_GTOP => eval { require GTop && GTop->VERSION >= 0.12 } || 0;
use Test;
use Event::Lib;

BEGIN {
    plan tests => (1000 * HAS_GTOP) || 1;
}

if (! HAS_GTOP) {
    skip("These tests require GTop");
    exit;
}

my $gtop = GTop->new;

# let perl reach a stable state of memory usage
timer_new(sub {})->add(0.000001) for 1..100;
Event::Lib::event_mainloop;

my $initial = $gtop->proc_mem($$)->vsize;

my $NUM = 100_000;

sub run {
    return if !$NUM--;
    if ($NUM % 100 == 0) {
	ok($gtop->proc_mem($$)->vsize, $initial);
    }
    shift->add(0.0000001);
}

timer_new(\&run)->add(0.000001);
event_mainloop;
