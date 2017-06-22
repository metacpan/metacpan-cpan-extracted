use strict;
use warnings;

# OK gearmand v1.0.6
# OK Gearman::Server v1.130.2

use Test::More;
use Test::Timer;

use lib '.';
use t::Server ();
use t::Worker qw/ new_worker /;

my $gts = t::Server->new();
my @job_servers = $gts->job_servers();
@job_servers || plan skip_all => $t::Server::ERROR;

my %cb = (
    sleep => sub {
        sleep $_[0]->arg;
        return 1;
    },
    sleep_three => [
        3,
        sub {
            my ($sleep, $return) = $_[0]->arg =~ m/^(\d+)(?::(.+))?$/;
            sleep $sleep;
            return $return;
            }
    ],
);

my @workers = map(new_worker(job_servers => [@job_servers], func => {%cb}),
    (0 .. int(rand(1) + 1)));

use_ok("Gearman::Client");

my $client = new_ok("Gearman::Client",
    [exceptions => 1, job_servers => [@job_servers]]);

## Test sleeping less than the timeout
subtest "sleep tree", sub {
    my $opt = {
        on_fail => sub { fail(explain(@_)) }
    };

    is(${ $client->do_task("sleep_three", "1:less", $opt) },
        "less", "We took less time than the worker timeout");

    # Do it three more times to check that "uniq" (implied "-")
    # works okay. 3 more because we need to go past the timeout.
    is(${ $client->do_task("sleep_three", "1:one", $opt) },
        "one", "We took less time than the worker timeout, again");

    is(${ $client->do_task("sleep_three", "1:two") },
        "two", "We took less time than the worker timeout, again");

    is(${ $client->do_task("sleep_three", "1:three") },
        "three", "We took less time than the worker timeout, again");

    # Now test if we sleep longer than the timeout
    is($client->do_task("sleep_three", 5),
        undef, "We took more time than the worker timeout");

    # This task and the next one would be hashed with uniq onto the
    # previous task, except it failed, so make sure it doesn"t happen.
    is($client->do_task("sleep_three", 5),
        undef, "We took more time than the worker timeout, again");

    is($client->do_task("sleep_three", 5),
        undef, "We took more time than the worker timeout, again, again");
};

## Check hashing on success, first job sends in 'a' for argument, second job
## should complete and return 'a' to the callback.
subtest "taskset a", sub {
    my $tasks = $client->new_task_set;
    $tasks->add_task(
        "sleep_three",
        "2:a",
        {
            uniq        => "something",
            on_complete => sub { is(${ $_[0] }, 'a', "'a' received") },
            on_fail => sub { fail() },
        }
    );

    sleep 1;

    $tasks->add_task(
        'sleep_three',
        '2:b',
        {
            uniq        => 'something',
            on_complete => sub {
                is(${ $_[0] }, 'a', "'a' received, we were hashed properly");
            },
            on_fail => sub { fail() },
        }
    );

    $tasks->wait;
};

#TODO there is some magic time_ok influence on following sleeping subtest, which fails if timeout ok
## Worker process times out (takes longer than timeout seconds).
subtest "timeout task", sub {
    plan skip_all => "doen't work properly with some gearmand";
    my $to = 3;
    time_ok(sub { $client->do_task("sleep", 5, { timeout => $to }) },
        $to, "Job that timed out after $to seconds returns failure");
};

#TODO review this subtest. It fails in both on_complete
#
## Check to make sure there are no hashing glitches with an explicit
## 'uniq' field. Both should fail.

subtest "timeout worker", sub {
    plan skip_all => "doen't work properly with some gearmand";
    my $tasks = $client->new_task_set;
    $tasks->add_task(
        "sleep_three",
        "10:a",
        {
            uniq        => "something",
            on_complete => sub { fail("This can't happen!") },
            on_fail     => sub { pass("We failed properly!") },
        }
    );

    note "sleep 5";
    sleep 5;
    note "slept 5";

    $tasks->add_task(
        "sleep_three",
        "10:b",
        {
            uniq        => "something",
            on_complete => sub { fail("This can't happen!") },
            on_fail     => sub { pass("We failed properly again!") },
        }
    );

    note "wait";
    $tasks->wait;
};

done_testing();
