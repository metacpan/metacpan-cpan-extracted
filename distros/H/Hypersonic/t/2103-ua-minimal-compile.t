use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use POSIX ":sys_wait_h";
use IO::Socket::INET;
use HypersonicTest qw(spawn_server wait_for_port);

# Test minimal (blocking-only) UA compilation


my $PORT = 34000 + ($$ % 1000);
my $server_pid;
my $server_log;

sub start_test_server {
    ($server_pid, $server_log) = spawn_server(sub {
        require Hypersonic;
        my $server = Hypersonic->new(cache_dir => "_test_minimal_server_$$");

        $server->get('/hello' => sub { 'Hello, World!' });
        $server->get('/json' => sub { '{"status":"ok"}' });
        $server->post('/echo' => sub {
            my ($req) = @_;
            return 'Echo: ' . ($req->body // '');
        }, { dynamic => 1 });

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
    system("rm -rf _test_minimal_server_*");
}

END { stop_test_server() }

start_test_server();
pass('Test server started');

use_ok('Hypersonic::UA');

subtest 'Minimal compile (no options)' => sub {
    # Compile with defaults (blocking only)
    eval { Hypersonic::UA->compile(cache_dir => "_test_minimal_client_$$") };
    ok(!$@, 'Minimal compile succeeded') or diag $@;

    # Check features
    ok(!$Hypersonic::UA::FEATURES{needs_async}, 'async not enabled');
    ok(!$Hypersonic::UA::FEATURES{needs_parallel}, 'parallel not enabled');
};

my $ua = Hypersonic::UA->new();
ok($ua, 'Created UA instance');

subtest 'Blocking GET works' => sub {
    my $res = $ua->get("http://127.0.0.1:$PORT/hello");
    ok($res, 'Got response');
    is($res->{status}, 200, 'Status 200');
    is($res->{body}, 'Hello, World!', 'Body matches');
};

subtest 'Blocking POST works' => sub {
    my $res = $ua->post("http://127.0.0.1:$PORT/echo", 'test data');
    ok($res, 'Got response');
    is($res->{status}, 200, 'Status 200');
    like($res->{body}, qr/Echo:.*test data/, 'POST body echoed');
};

subtest 'Async methods fail with helpful error' => sub {
    eval { $ua->get_async("http://127.0.0.1:$PORT/hello") };
    like($@, qr/get_async.*requires.*async => 1/, 'get_async gives helpful error');

    eval { $ua->tick() };
    like($@, qr/tick.*requires.*async => 1/, 'tick gives helpful error');

    eval { $ua->run() };
    like($@, qr/run.*requires.*async => 1/, 'run gives helpful error');

    eval { $ua->pending() };
    like($@, qr/pending.*requires.*async => 1/, 'pending gives helpful error');
};

subtest 'Parallel methods fail with helpful error' => sub {
    eval { $ua->parallel("http://example.com") };
    like($@, qr/parallel.*requires.*parallel => 1/, 'parallel gives helpful error');

    eval { $ua->race("http://example.com") };
    like($@, qr/race.*requires.*parallel => 1/, 'race gives helpful error');
};

# Cleanup
system("rm -rf _test_minimal_client_*");

done_testing();
