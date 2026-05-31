use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use POSIX ":sys_wait_h";
use IO::Socket::INET;
use HypersonicTest qw(spawn_server wait_for_port);

# Integration tests for Hypersonic::UA using real HTTP requests
# Note: UA currently returns hash refs, not Response objects


# Helper to get status/body from response (hash or object)
sub res_status { my $r = shift; ref($r) eq 'HASH' ? $r->{status} : $r->status }
sub res_body   { my $r = shift; ref($r) eq 'HASH' ? $r->{body}   : $r->body }

# Start a test server
my $PORT = 31000 + ($$ % 1000);
my $server_pid;
my $server_log;

sub start_test_server {
    ($server_pid, $server_log) = spawn_server(sub {
        require Hypersonic;
        my $server = Hypersonic->new(cache_dir => "_test_ua_server_$$");

        # Simple GET endpoints
        $server->get('/hello' => sub { 'Hello, World!' });
        $server->get('/json' => sub { '{"status":"ok","message":"Hello"}' });

        # POST endpoint
        $server->post('/post' => sub { 'POST received' });

        # PUT endpoint
        $server->put('/put' => sub { 'PUT received' });

        # DELETE endpoint
        $server->del('/delete' => sub { 'DELETE received' });

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
    do { local $@; eval { require File::Path; File::Path::remove_tree($_, { safe => 1, error => \my $e }) for grep { -e $_ } glob(qq(_test_ua_server_*)); }; };
}

END { stop_test_server() }

# Start test server
start_test_server();
pass('Test server started');

# Compile UA
use_ok('Hypersonic::UA');

# Compile with async support for callback tests
eval { Hypersonic::UA->compile(cache_dir => "_test_ua_client_$$", async => 1) };
ok(!$@, 'UA compiled successfully') or diag $@;

# Create UA instance
my $ua = Hypersonic::UA->new();
ok($ua, 'Created UA instance');

subtest 'GET /hello' => sub {
    my $res = $ua->get("http://127.0.0.1:$PORT/hello");
    ok($res, 'Got response');
    is(res_status($res), 200, 'Status 200');
    is(res_body($res), 'Hello, World!', 'Body matches');
};

subtest 'GET /json' => sub {
    my $res = $ua->get("http://127.0.0.1:$PORT/json");
    ok($res, 'Got response');
    is(res_status($res), 200, 'Status 200');
    like(res_body($res), qr/"status":"ok"/, 'JSON body');
};

subtest 'POST request' => sub {
    my $res = $ua->post("http://127.0.0.1:$PORT/post", '');
    ok($res, 'Got response');
    is(res_status($res), 200, 'Status 200');
    is(res_body($res), 'POST received', 'POST body');
};

subtest 'PUT request' => sub {
    my $res = $ua->put("http://127.0.0.1:$PORT/put", '');
    ok($res, 'Got response');
    is(res_status($res), 200, 'Status 200');
    is(res_body($res), 'PUT received', 'PUT body');
};

subtest 'DELETE request' => sub {
    my $res = $ua->delete("http://127.0.0.1:$PORT/delete");
    ok($res, 'Got response');
    is(res_status($res), 200, 'Status 200');
    is(res_body($res), 'DELETE received', 'DELETE body');
};

subtest 'Multiple sequential requests' => sub {
    for my $i (1..5) {
        my $res = $ua->get("http://127.0.0.1:$PORT/hello");
        is(res_status($res), 200, "Request $i status 200");
    }
};

# Cleanup
do { local $@; eval { require File::Path; File::Path::remove_tree($_, { safe => 1, error => \my $e }) for grep { -e $_ } glob(qq(_test_ua_client_*)); }; };

done_testing();
