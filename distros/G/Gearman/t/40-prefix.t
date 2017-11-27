use strict;
use warnings;

# OK gearmand v1.0.6
# OK Gearman::Server v1.130.2

use Test::More;
use Time::HiRes qw/sleep/;

use lib '.';
use t::Server ();
use t::Worker qw/ new_worker /;

my $gts = t::Server->new();
my @job_servers = $gts->job_servers();
@job_servers || plan skip_all => $t::Server::ERROR;

use_ok("Gearman::Client");
use_ok("Gearman::Task");

subtest "echo prefix", sub {
    my @p = qw/
        a
        b
        /;
    my ($func, %clients, %workers) = ("echo_prefix");
    foreach (@p) {
        my $prefix = join '_', "prefix", $_;
        $clients{$_} = new_ok("Gearman::Client",
            [prefix => $prefix, job_servers => [@job_servers]]);
        $workers{$_} = new_worker(
            job_servers => [@job_servers],
            prefix => $prefix,
            func => {
            $func => sub {
                join " from ", $_[0]->arg, $prefix;
            }
          }
        );
    } ## end foreach (@p)

    # basic do_task test
    foreach (@p) {
        is(
            ${ $clients{$_}->do_task("echo_prefix", "beep test") },
            join('_', "beep test from prefix",    $_),
            join(' ', "basic do_task() - prefix", $_)
        );
        is(
            ${
                $clients{$_}->do_task(
                    Gearman::Task->new("echo_prefix", \('beep test'))
                )
            },
            join('_', "beep test from prefix",            $_),
            join(' ', "Gearman::Task do_task() - prefix", $_)
        );
    } ## end foreach (@p)

    my %out;
    my %tasks = map { $_ => $clients{$_}->new_task_set() } @p;

    for my $k (keys %tasks) {
        $out{$k} = '';
        $tasks{$k}->add_task(
            'echo_prefix' => "$k",
            {
                on_complete => sub { $out{$k} .= ${ $_[0] } }
            }
        );
    } ## end for my $k (keys %tasks)

    $tasks{$_}->wait for keys %tasks;

    for my $k (sort keys %tasks) {
        is($out{$k}, "$k from prefix_$k", "taskset from client{$k}");
    }
};

## dispatch_background tasks also support prefixing
subtest "dispatch background", sub {
    my ($func, $prefix) = qw/
        echo_sleep
        prefix_a
        /;
    my $client = new_ok("Gearman::Client",
        [prefix => $prefix, job_servers => [@job_servers]]);
    my $worker = new_worker(
            job_servers => [@job_servers],
            prefix => $prefix,
            func => {
        $func => sub {
            my ($job) = @_;
            $job->set_status(1, 1);
            ## allow some time to read the status
            sleep 2;
            join " from ", $_[0]->arg, $prefix;
        }
      }
    );

    my $bg_task = new_ok("Gearman::Task", [$func, \("sleep prefix test")]);
    ok(my $handle = $client->dispatch_background($bg_task),
        "dispatch_background returns a handle");

    # wait for the task to be done
    my $status;
    my $n = 0;
    do {
        sleep 0.1;
        $n++;
        diag "still waiting..." if $n == 12;
        $status = $client->get_status($handle);
    } until ($status->percent && $status->percent == 1) or $n == 20;

    is($status->percent, 1, "Background task completed using prefix");
};

done_testing();
