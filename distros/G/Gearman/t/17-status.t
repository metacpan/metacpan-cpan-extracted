use strict;
use warnings;

# OK gearmand v1.0.6
# OK Gearman::Server v1.130.2

use Test::More;

use lib '.';
use t::Server ();
use t::Worker qw/ new_worker /;

my $gts = t::Server->new();
$gts || plan skip_all => $t::Server::ERROR;

my @job_servers = $gts->job_servers();
@job_servers || BAIL_OUT "no gearmand";

my $func = "sleep";

my $worker = new_worker(
    job_servers => [@job_servers],
    func        => {
        $func => sub {
            sleep $_[0]->arg;
            return 1;
            }
    }
);

use_ok("Gearman::Client");
my $client = new_ok("Gearman::Client", [job_servers => [@job_servers]]);

subtest "job server status", sub {

    # sleep before status check
    sleep 1;
    my $js_status = $client->get_job_server_status();
    foreach (@{ $client->job_servers() }) {
        isnt($js_status->{$_}->{$func}->{capable},
            0, "Correct capable jobs for $func");
        is($js_status->{$_}->{$func}->{running},
            0, "Correct running jobs for $func");
        is($js_status->{$_}->{$func}->{queued},
            0, "Correct queued jobs for $func");
    } ## end foreach (@{ $client->job_servers...})
};

subtest "job server jobs", sub {
    plan skip_all => "'jobs' command supported only by Gearman::Server";
    my $tasks = $client->new_task_set;
    $tasks->add_task(
        $func, 1,
        {
            on_fail => sub { fail(explain(@_)) },
        }
    );
    my $js_jobs = $client->get_job_server_jobs();
    is(scalar keys %$js_jobs, 1, "Correct number of running jobs");
    my $host = (keys %$js_jobs)[0];
    is($js_jobs->{$host}->{$func}->{key}, '', "Correct key for running job");
    isnt($js_jobs->{$host}->{$func}->{address},
        undef, "Correct address for running job");
    is($js_jobs->{$host}->{$func}->{listeners},
        1, "Correct listeners for running job");
    $tasks->wait;
};

subtest "job server clients", sub {
    plan skip_all => "'clients' command supported only by Gearman::Server";
    my $tasks = $client->new_task_set;
    $tasks->add_task(
        $func, 1,
        {
            on_fail => sub { fail(explain(@_)) },
        }
    );
    my $js_clients = $client->get_job_server_clients();
    foreach my $js (keys %$js_clients) {
        foreach my $client (keys %{ $js_clients->{$js} }) {
            next unless scalar keys %{ $js_clients->{$js}->{$client} };
            is($js_clients->{$js}->{$client}->{$func}->{key},
                '', "Correct key for running job via client");
            isnt($js_clients->{$js}->{$client}->{$func}->{address},
                undef, "Correct address for running job via client");
        } ## end foreach my $client (keys %{...})
    } ## end foreach my $js (keys %$js_clients)
    $tasks->wait;
};

done_testing();

