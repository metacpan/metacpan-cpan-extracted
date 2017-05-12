use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Gearman::Spawner;
use Gearman::Spawner::Server;

use Test::More;

my %available;
$available{Sync}++ if eval "use Gearman::Spawner::Client::Sync; 1";
$available{Async}++ if eval "use Gearman::Spawner::Client::Async; 1";
$available{AnyEvent}++ if eval "use Gearman::Spawner::Client::AnyEvent; use AnyEvent; 1";

if (!%available) {
    plan skip_all => 'no clients available';
}

plan tests => 10 * scalar keys %available;

my $server = Gearman::Spawner::Server->address;
my $spawner = Gearman::Spawner->new(
    servers => [$server],
    workers => {
        CountWorker => {
            count => 1,
        },
    },
);

my %clients = (
    Sync => sub {
        my $client = shift;
        return sub {
            my $method = shift;
            $client->run_method(qw( class CountWorker method ), $method);
        };
    },
    Async => sub {
        my $client = shift;
        return sub {
            my $method = shift;
            my ($ret, $error);
            my $leave = sub {
                Danga::Socket->SetPostLoopCallback(sub { 0 });
            };
            $client->run_method(
                class => 'CountWorker',
                method => $method,
                success_cb => sub {
                    $ret = shift;
                    return $leave->();
                },
                error_cb => sub {
                    $error = shift;
                    return $leave->();
                },
                timeout => 1,
            );
            Danga::Socket->EventLoop;
            Danga::Socket->SetPostLoopCallback(sub { 1 });
            die $error if $error;
            return $ret;
        };
    },
    AnyEvent => sub {
        my $client = shift;
        return sub {
            my $method = shift;
            my $cv = AnyEvent->condvar;
            my ($ret, $error);
            $client->run_method(
                class => 'CountWorker',
                method => $method,
                success_cb => sub {
                    $ret = shift;
                    $cv->send;
                },
                error_cb => sub {
                    $error = shift;
                    $cv->send;
                },
                timeout => 1,
            );
            $cv->recv;
            die $error if $error;
            return $ret;
        };
    },
);

for my $type (sort keys %available) {
    my $client = "Gearman::Spawner::Client::$type"->new(job_servers => [$server]);
    my $call = $clients{$type}->($client);

    my $pid1 = $call->("pid");
    is($call->("inc"), 1, "$type: worker 1: inc 1");
    is($call->("inc"), 2, "$type: worker 1: inc 2");
    is($call->("pid"), $pid1, "$type: same worker after incs");

    # exception in worker should not kill it
    eval { $call->("die") };
    is($call->("pid"), $pid1, "$type: same worker after die");
    is($call->("inc"), 3, "$type: worker 1: inc 3");

    # worker exiting should
    eval { $call->("exit") };
    my $pid2 = $call->("pid");
    isnt($pid2, $pid1, "$type: new worker after exit");
    is($call->("inc"), 1, "$type: worker 2: inc 1");

    ok(kill("INT", $pid2), "$type: killed worker 2");
    my $pid3 = $call->("pid");
    isnt($pid3, $pid2, "$type: new worker after kill");
    is($call->("inc"), 1, "$type: worker 3: inc 1");

    # cleanup
    eval { $call->("exit") };
    waitpid $pid3, 0;
}
