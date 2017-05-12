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

use_ok("Gearman::Client");

my $client = new_ok("Gearman::Client",
    [exceptions => 1, job_servers => [@job_servers]]);

my $func = "long";

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

## Test dispatch_background and get_status.
subtest "dispatch background", sub {
    my $handle = $client->dispatch_background(
        $func => undef,
        {
            on_complete => sub { note "complete", ${ $_[0] } },
            on_fail     => sub { fail(explain(@_)) },
        }
    );

    # wait for job to start being processed:
    sleep 1;

    ok($handle, 'Got a handle back from dispatching background job');
    ok(my $status = $client->get_status($handle), "get_status");
    ok($status->known,   'Job is known');
    ok($status->running, 'Job is still running');
    is($status->percent, .5, 'Job is 50 percent complete');

    do {
        sleep 1;
        $status = $client->get_status($handle);
        note $status->percent;
    } until $status->percent == 1;
};

done_testing();

