use strict;
use warnings;

# OK gearmand v1.0.6
use Proc::Guard;
use Test::Exception;
use Test::More;
use List::Util qw/ sum /;

use Storable qw/
    freeze
    thaw
    /;

use lib '.';
use t::Server ();

my $gts = t::Server->new();
$gts || plan skip_all => $t::Server::ERROR;

plan tests => 5;

use_ok("Gearman::Client");
use_ok("Gearman::Worker");

my @job_servers = $gts->job_servers(int(rand(1) + 1));
my $func        = "sum";
my @a           = map { int(rand(100)) } (0 .. int(rand(10) + 5));

my $client = new_ok("Gearman::Client",
    [exceptions => 1, job_servers => [@job_servers]]);

subtest "work complete", sub {
    plan tests => 3;

    ok(my $worker = worker_complete(job_servers => [@job_servers]), "worker");

    ok my $res = $client->do_task(
        $func => freeze([@a]),
        {
            on_exception => sub { fail("exception") }
        },
        ),
        "do task";
    is(${$res}, sum(@a), "result");
};

subtest "work fail", sub {

    # because no Gearman::Server do not support protocol commands WORK_DATA and WORK_WARNING
    $ENV{AUTHOR_TESTING} || plan skip_all => 'without $ENV{AUTHOR_TESTING}';
    plan tests => 3;

    ok(my $worker = worker_fail(job_servers => [@job_servers]), "worker");
    my $res = $client->do_task(
        $func => undef,
        {
            on_fail => sub {
                is(shift, "$$ job fail", "on fail callback");
            },
            on_exception => sub { fail("exception") }
        },
    );
    is($res, undef, "no result");
};

done_testing();

sub worker_complete {
    my (%args) = @_;
    my $w = Gearman::Worker->new(%args);

    my $cb = sub {
        my ($job) = @_;
        my @i = @{ thaw($job->arg) };
        $w->send_work_complete($job, sum(@i));
        return;
    };

    $w->register_function($func, $cb);

    return _work($w);
} ## end sub worker_complete

sub worker_fail {
    my (%args) = @_;
    my $w = Gearman::Worker->new(%args);

    my $cb = sub {
        my ($job) = @_;
        $w->send_work_fail($job, join(' ', getppid(), "job fail"));
        return;
    };

    $w->register_function($func, $cb);

    return _work($w);
} ## end sub worker_fail

sub _work {
    my $w  = shift;
    my $pg = Proc::Guard->new(
        code => sub {
            $w->work();
        }
    );

    return $pg;
} ## end sub _work
