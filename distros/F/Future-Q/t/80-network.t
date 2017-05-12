use strict;
use warnings;
use Test::More;
use Test::Memory::Cycle;
use Future::Q;
use FindBin;
use lib "$FindBin::RealBin";
use testlib::Utils qw(init_warn_handler test_log_num);

note("--- complicated then/resolve network");

init_warn_handler;

## t: a link created by then() method
## r: a link created by resolve() method
## 
## [0]-t-[1]-t-[2]-r-[5]
##           r-[3]-r-[6]
##                 t-[7]
##           t-[4]

sub create_network {
    my @network = ();
    $network[0] = Future::Q->new;
    $network[1] = $network[0]->then();
    $network[2] = $network[1]->then();
    $network[3] = Future::Q->new->resolve($network[1]);
    $network[4] = $network[1]->then();
    $network[5] = Future::Q->new->resolve($network[2]);
    $network[6] = Future::Q->new->resolve($network[3]);
    $network[7] = $network[3]->then();
    return \@network;
}

test_log_num sub {
    note("--- initial state");
    my $network = create_network;
    memory_cycle_ok $network, "no memory cycle in the whole network";
    ok $network->[$_]->is_pending, "f$_ pending OK" foreach 0..$#$network;

    note("--- fulfill");
    $network->[0]->fulfill(10);
    is scalar($network->[$_]->get), 10, "f$_ result OK" foreach 0..$#$network;
}, 0, "no warning";

test_log_num sub {
    note("--- reject");
    my $network = create_network;
    $network->[0]->reject(20);
    is scalar($network->[$_]->failure), 20, "f$_ failure OK" foreach 0..$#$network;
}, 4, "4 warnings from the leaf futures";

{
    note("--- canceling at any position makes the whole network cancelled");
    my $cancel_index = -1;
    while(1) {
        $cancel_index++;
        my $network = create_network;
        last if $cancel_index >= @$network;
        
        note("--- cancel at $cancel_index");
        test_log_num sub {
            $network->[$cancel_index]->cancel();
            ok $network->[$_]->is_cancelled, "f$_ cancelled OK" foreach 0..$#$network;
            undef $network;
        }, 0, "no warning";
    }
}

done_testing;

