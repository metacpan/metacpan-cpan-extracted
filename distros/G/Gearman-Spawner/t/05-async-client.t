use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
my $num_tests = 17;

if (eval "use Gearman::Spawner::Client::Async; 1") {
    plan tests => $num_tests;
}
else {
    plan skip_all => 'asynchronous client not available';
}

use ClientTest;
use Danga::Socket;
use Time::HiRes 'time';

my $tester = eval { ClientTest->new };
SKIP: {
$@ && skip $@, $num_tests;

my @tests = $tester->tests;

my $client = Gearman::Spawner::Client::Async->new(job_servers => [$tester->server]);

my $next_test;
$next_test = sub {
    return Danga::Socket->SetPostLoopCallback(sub { 0 }) unless @tests;
    my $test = shift @tests;
    $client->run_method(
        class => $tester->class,
        method => $test->[0],
        data => $test->[1],
        success_cb => sub {
            $test->[2]->(@_);
            $next_test->();
        },
        error_cb => sub {
            my $err = shift;
            fail("$test->[0] tripped on_failure: $err"),
            $next_test->();
        },
    );
};
$next_test->();
Danga::Socket->EventLoop;
Danga::Socket->SetPostLoopCallback(sub { 1 });

# test timeout
my $start = time;
$client->run_method(
    class => 'Nonexistent',
    method => 'fake',
    data => undef,
    success_cb => sub {
        fail('impossible');
    },
    error_cb => sub {
        my $err = shift;
        like($err, qr/timeout/, 'timeout');
        ok(time - $start > 0.25, 'nonimmediate return');
        Danga::Socket->SetPostLoopCallback(sub { 0 });
    },
    timeout => 0.25,
);
Danga::Socket->EventLoop;

}
