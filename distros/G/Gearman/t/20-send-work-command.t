use strict;
use warnings;

# OK gearmand v1.0.6
use Proc::Guard;
use Test::Exception;
use Test::More;
use Storable qw/
    freeze
    thaw
    /;

# because no Gearman::Server do not support protocol commands WORK_DATA and WORK_WARNING
$ENV{AUTHOR_TESTING} || plan skip_all => 'without $ENV{AUTHOR_TESTING}';

use lib '.';
use t::Server ();

my $gts = t::Server->new();
my @job_servers = $gts->job_servers(int(rand(1) + 1));
@job_servers || plan skip_all => $t::Server::ERROR;

use_ok("Gearman::Client");
use_ok("Gearman::Worker");

my $func        = "sum";
my @a           = map { int(rand(100)) } (0 .. int(rand(10) + 5));

foreach my $method (qw/data warning/) {
    my $str = join('_', "work", $method);
    subtest $str, sub {
        plan tests => 3;

        my $client = new_ok("Gearman::Client",
            [exceptions => 1, job_servers => [@job_servers]]);
        my $worker
            = worker(join('_', "send", $str), job_servers => [@job_servers]);

        my ($i, $r) = (0, 0);
        my $res = $client->do_task(
            $func => freeze([@a]),
            {
                join('_', "on", $method) => sub {
                    my ($ref) = @_;
                    $r += $a[$i];
                    $i++;
                },
                on_exception => sub { fail("exception") }
            },
        );
        is(scalar(@a), $i, "on_$method count");
        is(${$res},    $r, "$func result");
    };
} ## end foreach my $method (qw/data warning/)

done_testing();

sub worker {
    my ($send_method, %args) = @_;
    my $w = Gearman::Worker->new(%args);

    my $cb = sub {
        my ($job) = @_;
        my $sum   = 0;
        my @i     = @{ thaw($job->arg) };
        foreach (@i) {
            $sum += $_;
            $w->$send_method($job, $sum);
        }
        return $sum;
    };

    $w->register_function($func, $cb);

    my $pg = Proc::Guard->new(
        code => sub {
            $w->work(
                stop_if => sub {
                    my ($idle) = @_;
                    return $idle;
                }
            );
        }
    );

    return $pg;
} ## end sub worker
