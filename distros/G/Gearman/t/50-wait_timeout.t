use strict;
use warnings;

# OK gearmand v1.0.6

use Test::More;
use Test::Timer;

use lib '.';
use t::Server ();
use t::Worker qw/ new_worker /;

my $gts = t::Server->new();
$gts || plan skip_all => $t::Server::ERROR;

my @job_servers = $gts->job_servers();
@job_servers || BAIL_OUT "no gearmand";

my $func = "long";

use_ok("Gearman::Client");
my $client = new_ok("Gearman::Client", [job_servers => @job_servers]);

my $worker = new_worker(
    job_servers => [@job_servers],
    func        => {
        $func => sub {
            my ($job) = @_;
            $job->set_status(50, 100);
            sleep 2;
            $job->set_status(100, 100);
            sleep 2;
            return $job->arg;
            }
    }
);

subtest "wait with timeout", sub {
    ok(my $tasks = $client->new_task_set, "new_task_set");
    isa_ok($tasks, 'Gearman::Taskset');

    my ($iter, $completed, $failed) = (0, 0, 0);

    my $opt = {
        uniq        => $iter,
        on_complete => sub {
            $completed++;
            note "Got result for $iter";
        },
        on_fail => sub {
            $failed++;
        },
    };

    # For a total of 5 events, that will be 20 seconds; till they complete.
    foreach $iter (1 .. 5) {
        ok($tasks->add_task($func, $iter, $opt), "add_task('$func', $iter)");
    }

    my $to = 11;

    time_ok(sub { $tasks->wait(timeout => $to) }, $to, "timeout");
    ok($completed > 0, "at least one job is completed");
    is($failed, 0, "no failed jobs");
};

subtest "$func args", sub {
    my $tasks = $client->new_task_set;
    isa_ok($tasks, 'Gearman::Taskset');

    my $arg = 'x' x (5 * 1024 * 1024);

    $tasks->add_task(
        $func,
        \$arg,
        {
            on_complete => sub {
                my $rr = shift;
                if (length($$rr) != length($arg)) {
                    fail(     "Large job failed size check: got "
                            . length($$rr)
                            . ", want "
                            . length($arg));
                } ## end if (length($$rr) != length...)
                elsif ($$rr ne $arg) {
                    fail("Large job failed content check");
                }
                else {
                    pass("Large job succeeded");
                }
            },
            on_fail => sub {
                fail("Large job failed");
            },
        }
    );

    my $to = 10;
    time_ok(sub { $tasks->wait(timeout => $to) }, $to, "timeout");
};

done_testing();
