use strict;
use warnings;

# OK gearmand v1.0.6
# OK Gearman::Server v1.130.2

use List::Util;
use Test::More;

use lib '.';
use t::Server ();
use t::Worker qw/ new_worker /;

my $gts = t::Server->new();
my @job_servers = $gts->job_servers();
@job_servers || plan skip_all => $t::Server::ERROR;

use_ok("Gearman::Client");

my $client = new_ok("Gearman::Client",
    [exceptions => 1, job_servers => [@job_servers]]);

## Test high_priority.
## Create a taskset with 4 tasks, and have the 3rd fail.
## In on_fail, add a new task with high priority set, and make sure it
## gets executed before task 4. To make this reliable, we need to first
## kill off all but one of the worker processes.
subtest "hight priority", sub {
    my $tasks = $client->new_task_set;
    my $out   = '';
    $tasks->add_task(
        echo_ws => 1,
        {
            on_complete => sub { $out .= ${ $_[0] } },
            on_fail => sub { fail(explain(@_)) },
        }
    );

    $tasks->add_task(
        echo_ws => 2,
        {
            on_complete => sub { $out .= ${ $_[0] } },
            on_fail => sub { fail(explain(@_)) },
        }
    );

    $tasks->add_task(
        echo_ws => 'x',
        {
            on_fail => sub {
                $tasks->add_task(
                    echo_ws => 'p',
                    {
                        on_complete => sub {
                            $out .= ${ $_[0] };
                        },
                        high_priority => 1
                    }
                );
            },
        }
    );

    $tasks->add_task(
        echo_ws => 3,
        {
            on_complete => sub { $out .= ${ $_[0] } },
            on_fail => sub { fail(explain(@_)) },
        }
    );

    $tasks->add_task(
        echo_ws => 4,
        {
            on_complete => sub { $out .= ${ $_[0] } },
            on_fail => sub { fail(explain(@_)) },
        }
    );

    $tasks->add_task(
        echo_ws => 5,
        {
            on_complete => sub { $out .= ${ $_[0] } },
            on_fail => sub { fail(explain(@_)) },
        }
    );

    $tasks->add_task(
        echo_ws => 6,
        {
            on_complete => sub { $out .= ${ $_[0] } },
            on_fail => sub { fail(explain(@_)) },
        }
    );

    note "start workers";
    my $pg = new_worker(
        job_servers => [@job_servers],
        func        => {
            echo_ws => sub {
                select undef, undef, undef, 0.25;
                $_[0]->arg eq 'x' ? undef : $_[0]->arg;
                }
        }
    );
    note "worker pid:", $pg->pid;

    note "wait";
    $tasks->wait;
    like($out, qr/p.+6/, 'High priority tasks executed in priority order.');
};

done_testing();
