use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use POSIX ":sys_wait_h";
use IO::Socket::INET;
use Time::HiRes qw(time);
use HypersonicTest qw(spawn_server wait_for_port);

# Async integration tests for Hypersonic::UA
# Note: True async (futures) require additional compilation
# This test focuses on callback-based async which works now


# Helper to get status/body from response (hash or object)
sub res_status { my $r = shift; ref($r) eq 'HASH' ? $r->{status} : $r->status }
sub res_body   { my $r = shift; ref($r) eq 'HASH' ? $r->{body}   : $r->body }

my $PORT = 32000 + ($$ % 1000);
my $server_pid;
my $server_log;

sub start_test_server {
    ($server_pid, $server_log) = spawn_server(sub {
        require Hypersonic;
        my $server = Hypersonic->new(cache_dir => "_test_async_server_$$");

        # Fast endpoint
        $server->get('/fast' => sub { 'fast' });

        # Slow endpoint - must be dynamic to actually execute sleep at runtime
        # Note: Routes with :param are automatically dynamic, access via $req->param('name')
        $server->get('/slow/:ms' => sub {
            my ($req) = @_;
            my $ms = $req->param('ms') // 100;
            select(undef, undef, undef, $ms / 1000);
            return "waited $ms ms";
        });

        # Counter endpoint for testing multiple requests
        # Access param via $req->param('n') or shorthand $req->n
        $server->get('/count/:n' => sub {
            my ($req) = @_;
            return $req->param('n');
        });

        $server->compile();
        $server->run(port => $PORT, workers => 1);
    });

    wait_for_port($PORT, { pid => $server_pid, log => $server_log, tries => 50 })
        or die "Server failed to start";
    return 1;
}

sub stop_test_server {
    if ($server_pid) {
        kill('TERM', $server_pid);
        waitpid($server_pid, 0);
    }
    system("rm -rf _test_async_server_*");
}

END { stop_test_server() }

start_test_server();
pass('Test server started');

use_ok('Hypersonic::UA');

# Compile with async support for callback tests
eval { Hypersonic::UA->compile(cache_dir => "_test_async_client_$$", async => 1) };
ok(!$@, 'UA compiled successfully') or diag $@;

my $ua = Hypersonic::UA->new();
ok($ua, 'Created UA instance');

subtest 'Callback-based async GET' => sub {
    my $callback_called = 0;
    my $callback_response;

    $ua->get("http://127.0.0.1:$PORT/fast", sub {
        my ($res) = @_;
        $callback_called = 1;
        $callback_response = $res;
    });

    ok($callback_called, 'Callback was called');
    ok($callback_response, 'Callback received response');
    is(res_status($callback_response), 200, 'Callback response status 200');
    is(res_body($callback_response), 'fast', 'Callback response body correct');
};

subtest 'Multiple sequential requests' => sub {
    my @results;
    my $start = time();

    for my $i (1..5) {
        my $res = $ua->get("http://127.0.0.1:$PORT/count/$i");
        push @results, $res;
    }

    my $elapsed = time() - $start;

    is(scalar(@results), 5, 'Got 5 results');
    for my $i (0..4) {
        is(res_status($results[$i]), 200, "Request $i status 200");
        is(res_body($results[$i]), $i + 1, "Request $i body correct");
    }
    note("5 sequential requests in ${elapsed}s");
};

subtest 'Mixed GET and POST' => sub {
    # GET
    my $get_res = $ua->get("http://127.0.0.1:$PORT/fast");
    is(res_body($get_res), 'fast', 'GET completed');

    # Another GET to dynamic endpoint
    my $count_res = $ua->get("http://127.0.0.1:$PORT/count/42");
    is(res_body($count_res), '42', 'Dynamic GET completed');
};

subtest 'Slow endpoint' => sub {
    my $start = time();
    my $res = $ua->get("http://127.0.0.1:$PORT/slow/100");
    my $elapsed = time() - $start;

    is(res_status($res), 200, 'Got response from slow endpoint');
    like(res_body($res), qr/waited 100 ms/, 'Body indicates wait time');
    ok($elapsed >= 0.05, "Request took ${elapsed}s (expected >= 0.05s)");
};

# Cleanup
system("rm -rf _test_async_client_*");

done_testing();
