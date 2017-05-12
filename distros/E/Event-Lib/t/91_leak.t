# Memory leak test.
# We create and delete 100_000 events in chunks of 100.
# After each chunk we test if memory usage has grown.
# If it has, it means there was a memory leak.
# Unlike 90_leak.t, in this test each event is triggered
# and removed via an explicit del().

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

sub run {}

# let perl reach a stable state of memory usage
timer_new(\&run)->add(0.000001) for 1..100;
Event::Lib::event_mainloop;

my $initial = $gtop->proc_mem($$)->vsize;
for (1 .. 1000) {
    timer_new(\&run)->add(0.000001) for 1..100;
    event_mainloop;
    ok($gtop->proc_mem($$)->vsize, $initial);
}
