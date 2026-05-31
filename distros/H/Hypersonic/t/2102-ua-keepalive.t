use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use POSIX ":sys_wait_h";
use IO::Socket::INET;
use Time::HiRes qw(time);
use HypersonicTest qw(spawn_server wait_for_port);

# Connection pooling and keep-alive tests


# Helper to get status/body from response (hash or object)
sub res_status { my $r = shift; ref($r) eq 'HASH' ? $r->{status} : $r->status }
sub res_body   { my $r = shift; ref($r) eq 'HASH' ? $r->{body}   : $r->body }

my $PORT = 33000 + ($$ % 1000);
my $server_pid;
my $server_log;

sub start_test_server {
    ($server_pid, $server_log) = spawn_server(sub {
        require Hypersonic;
        my $server = Hypersonic->new(cache_dir => "_test_keepalive_server_$$");

        $server->get('/ping' => sub { 'pong' });

        # Return connection info - must be dynamic to access $req
        $server->get('/conninfo' => sub {
            my ($req) = @_;
            my $conn = $req->header('Connection') // 'none';
            return qq({"connection":"$conn"});
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
    do { local $@; eval { require File::Path; File::Path::remove_tree($_, { safe => 1, error => \my $e }) for grep { -e $_ } glob(qq(_test_keepalive_server_*)); }; };
}

END { stop_test_server() }

start_test_server();
pass('Test server started');

use_ok('Hypersonic::UA');

# Compile with minimal features (blocking only - no async needed for keepalive test)
eval { Hypersonic::UA->compile(cache_dir => "_test_keepalive_client_$$") };
ok(!$@, 'UA compiled successfully') or diag $@;

my $ua = Hypersonic::UA->new();
ok($ua, 'Created UA instance');

subtest 'Multiple sequential requests reuse connections' => sub {
    # Make several requests - connection pooling should kick in
    my $start = time();
    for my $i (1..10) {
        my $res = $ua->get("http://127.0.0.1:$PORT/ping");
        is(res_status($res), 200, "Request $i succeeded");
        is(res_body($res), 'pong', "Request $i body correct");
    }
    my $elapsed = time() - $start;

    # With connection reuse, 10 requests should be fast
    ok($elapsed < 2, "10 requests completed in ${elapsed}s (should reuse connections)");
};

subtest 'Keep-alive header sent' => sub {
    my $res = $ua->get("http://127.0.0.1:$PORT/conninfo");
    is(res_status($res), 200, 'Got response');
    # Check if keep-alive or close
    my $body = res_body($res);
    ok($body =~ /\"connection\"/, 'Response has connection info');
};

subtest 'Rapid fire requests' => sub {
    my @responses;
    my $start = time();

    for (1..20) {
        push @responses, $ua->get("http://127.0.0.1:$PORT/ping");
    }

    my $elapsed = time() - $start;

    my $success_count = grep { res_status($_) == 200 } @responses;
    is($success_count, 20, 'All 20 requests succeeded');
    note("20 sequential requests in ${elapsed}s");
};

# Cleanup
do { local $@; eval { require File::Path; File::Path::remove_tree($_, { safe => 1, error => \my $e }) for grep { -e $_ } glob(qq(_test_keepalive_client_*)); }; };

done_testing();
