use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
my $num_tests = 21;

if (eval "use Gearman::Spawner::Client::AnyEvent; use AnyEvent; 1") {
    plan tests => $num_tests;
}
else {
    plan skip_all => 'AnyEvent client not available';
}

use Time::HiRes 'time';
use ClientTest;

my $tester = eval { ClientTest->new };
SKIP: {
$@ && skip $@, $num_tests;

my @tests = $tester->tests;

my $client = Gearman::Spawner::Client::AnyEvent->new(job_servers => [$tester->server]);

my $cv = AnyEvent->condvar;
my $next_test;
$next_test = sub {
    return $cv->send unless @tests;
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
$cv->recv;

# test timeout
my $start = time;
my $cv2 = AnyEvent->condvar;
$client->run_method(
    class => 'Nonexistent',
    method => 'fake',
    data => undef,
    success_cb => sub {
        fail('impossible');
        $cv2->send;
    },
    error_cb => sub {
        my $err = shift;
        like($err, qr/timeout/, 'client timeout');
        ok(time - $start > 0.25, 'nonimmediate return');
        $cv2->send;
    },
    timeout => 0.25,
);
is(scalar keys %{ $client->{cancel_timers} }, 1, 'timer is live');
$cv2->recv;
is(scalar keys %{ $client->{cancel_timers} }, 0, 'timer is dead');

# make sure timeout doesn't fire on successful job
my $cv3 = AnyEvent->condvar;
my $timer = AnyEvent->timer(after => 0.5, cb => sub { $cv3->send });
my $success;
my $timeout_fired;
$client->run_method(
    class => 'MethodWorker',
    method => 'constant',
    success_cb => sub {
        $success++;
    },
    error_cb => sub {
        my $err = shift;
        $timeout_fired++ if $err =~ /timeout/;
    },
    timeout => 0.25,
);
$cv3->recv;
ok($success, "job succeeded");
ok(!$timeout_fired, "timeout on successful job didn't fire");

}
