# Memory leak test.
# We create and delete 100_000 events in chunks of 100.
# After each chunk we test if memory usage has grown.
# If it has, it means there was a memory leak.

# XXX This test does NOT work with Test::More as
# XXX that will apparently allocate more and more 
# XXX memory.

package A;

use Event::Lib;

sub new {
    my %data = ();
    return bless \%data, __PACKAGE__;
}

sub event {
    my ($self, $id, $val) = @_;
    $self->{"event_$id"} = $val if $val || @_ == 3;
    return $self->{"event_$id"};
}

sub add {
    my ($self, $id) = @_;
    my $t = Event::Lib::timer_new(sub { warn "timer expired\n" });
    $self->event($id, $t);
    $t->add(0.00001);
}

sub del {
    my ($self, $id) = @_;
    if (my $t = $self->event($id)) {
        $t->remove;
        $self->event($id, undef);
    }
}

package main;

use constant HAS_GTOP => eval { require GTop && GTop->VERSION >= 0.12 } || 0;
use Test;

BEGIN {
    plan tests => (1000 * HAS_GTOP) || 1;
}

if (! HAS_GTOP) {
    skip("These tests require GTop");
    exit;
}

my $gtop = GTop->new;
my $self = A->new();

Event::Lib::timer_new(\&run_timers)->add(0.001);
Event::Lib::event_mainloop();

{
    # Allocate some memory:
    # on leavning this block, the memory is marked as reusable. 
    # For the following tests, this pre-allocated memory should
    # suffice. If not => test failure because we leaked
    my @MEMORY_HOG = (1 .. 50_000);
}

sub run_timers {
    my $initial = $gtop->proc_mem($$)->vsize;
    for (1..1000) {
        $self->add($_) for 1..100;
        $self->del($_) for 1..100;
	ok($gtop->proc_mem($$)->vsize, $initial);
    }
}


