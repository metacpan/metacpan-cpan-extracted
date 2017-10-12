use strict;
use warnings;

# OK gearmand v1.0.6

use List::Util qw/ sum /;
use Storable qw/
    freeze
    thaw
    /;
use Test::Exception;
use Test::More;

use lib '.';
use t::Server ();
use t::Worker qw/ new_worker /;

my $gts         = t::Server->new();
my @job_servers = $gts->job_servers(int(rand(1) + 1));
@job_servers || plan skip_all => $t::Server::ERROR;
plan tests => 4;

use_ok("Gearman::Client");

my $client = new_ok("Gearman::Client",
    [exceptions => 1, job_servers => [@job_servers]]);

my $func = "sum";
my $cb   = sub {
    my $sum = 0;
    $sum += $_ for @{ thaw($_[0]->arg) };
    return $sum;
};

my @workers
    = map(new_worker(job_servers => [@job_servers], func => { $func, $cb }),
    (0 .. int(rand(1) + 1)));

subtest "taskset 1", sub {
    plan tests => 7;
    throws_ok { $client->do_task(sum => []) }
    qr/Function argument must be scalar or scalarref/,
        'do_task does not accept arrayref argument';

    my @a   = _rl();
    my $sum = sum(@a);
    my $out = $client->do_task(
        sum => freeze([@a]),
        {
            on_fail     => sub { fail(explain(@_)) },
            on_complete => sub { pass "on complete hook" }
        }
    );

    is($$out, $sum, "do_task returned $sum for sum");

    undef($out);

    isa_ok my $ts = $client->new_task_set, "Gearman::Taskset";

    my $failed = 0;
    ok my $handle = $ts->add_task(
        sum => freeze([@a]),
        {
            on_complete => sub { $out    = ${ $_[0] } },
            on_fail     => sub { $failed = 1 }
        }
        ),
        "add task";

    note "wait";
    $ts->wait;

    is($out,    $sum, "add_task/wait returned $sum for sum");
    is($failed, 0,    'on_fail not called on a successful result');
};

subtest "taskset 2", sub {
    plan tests => 5;
    isa_ok my $ts = $client->new_task_set, "Gearman::Taskset";

    my @a  = _rl();
    my $sa = sum(@a);
    my @sums;
    ok $ts->add_task(
        sum => freeze([@a]),
        { on_complete => sub { $sums[0] = ${ $_[0] } }, }
        ),
        "add task";

    my @b  = _rl();
    my $sb = sum(@b);
    ok $ts->add_task(
        sum => freeze([@b]),
        {
            on_complete => sub { $sums[1] = ${ $_[0] } },
            on_fail => sub { fail(explain(@_)) }
        }
        ),
        "add task";

    $ts->wait;

    is($sums[0], $sa, "First task completed (sum is $sa)");
    is($sums[1], $sb, "Second task completed (sum is $sb)");
};

done_testing();

sub _rl {
    return map { int(rand(100)) } (0 .. int(rand(10) + 1));
}
