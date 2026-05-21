use strict;
use warnings;
use Test::More;
use File::Temp ();
use EV;
use EV::cares qw(:status :types);

# Multiple resolver instances on the SAME EV (default) loop must not
# cross-talk: each has its own c-ares channel, its own hosts file, its
# own per-channel options.  This catches any per-loop-vs-per-channel
# assumption mistakes.

# Two distinct hosts files: identical query name, different answers
my $tmp_a = File::Temp->new(SUFFIX => '.hosts');
print $tmp_a "10.0.0.1 shared-host\n";
close $tmp_a;

my $tmp_b = File::Temp->new(SUFFIX => '.hosts');
print $tmp_b "10.0.0.2 shared-host\n";
close $tmp_b;

my $r_a = EV::cares->new(lookups => 'f', hosts_file => $tmp_a->filename);
my $r_b = EV::cares->new(lookups => 'f', hosts_file => $tmp_b->filename);

isnt("$r_a", "$r_b", 'two resolvers are distinct instances');

# Fan out simultaneously
my (@got_a, @got_b);
my ($done_a, $done_b);

$r_a->resolve('shared-host', sub { @got_a = @_; $done_a = 1 });
$r_b->resolve('shared-host', sub { @got_b = @_; $done_b = 1 });

my $t = EV::timer 5, 0, sub { $done_a = $done_b = 1 };
EV::run until $done_a && $done_b;

is($got_a[0], ARES_SUCCESS, 'resolver A succeeded');
is($got_b[0], ARES_SUCCESS, 'resolver B succeeded');

ok(grep({ $_ eq '10.0.0.1' } @got_a[1..$#got_a]),
   'A gets its own answer (10.0.0.1)');
ok(grep({ $_ eq '10.0.0.2' } @got_b[1..$#got_b]),
   'B gets its own answer (10.0.0.2)');

ok(!grep({ $_ eq '10.0.0.2' } @got_a[1..$#got_a]),
   'A did not see B answer');
ok(!grep({ $_ eq '10.0.0.1' } @got_b[1..$#got_b]),
   'B did not see A answer');

is($r_a->active_queries, 0, 'A active_queries == 0 after callback');
is($r_b->active_queries, 0, 'B active_queries == 0 after callback');

# Many resolvers concurrently
{
    my @resolvers = map EV::cares->new(lookups => 'f'), 1..5;
    my $count = 0;
    for my $r (@resolvers) {
        $r->resolve('localhost', sub { $count++ });
    }
    my $t2 = EV::timer 5, 0, sub { EV::break };
    EV::run until $count >= 5;
    is($count, 5, '5 concurrent resolvers each got their callback');
    is($_->active_queries, 0, 'each instance settles to 0') for @resolvers;
}

# Independent destroy: destroying one resolver leaves others alive
{
    my $live = EV::cares->new(lookups => 'f');
    my $doomed = EV::cares->new(lookups => 'f');
    $doomed->destroy;
    is($doomed->is_destroyed, 1, 'doomed is destroyed');
    is($live->is_destroyed,   0, 'live is unaffected');

    my $done;
    $live->resolve('localhost', sub { $done = 1 });
    my $t3 = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;
    pass('live resolver still works after sibling destroy');
}

done_testing;
