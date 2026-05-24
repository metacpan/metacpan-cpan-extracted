use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use IO::Socket::INET;
use HypersonicTest qw(spawn_server wait_for_port);


use Hypersonic;
use Hypersonic::UA;

plan skip_all => 'fork not available' unless $^O ne 'MSWin32';

my $port = 18878 + ($$ % 1000);
my $cache_dir = "_test_blocking_cache_$$";

# Spawn server with captured stderr so we can diag() actual errors
# (was a flaky "Test server is running" on perl 5.22.4 smoker because
# we'd race the listener accept queue with no diagnostic when it lost).
my ($pid, $log) = spawn_server(sub {
    my $server = Hypersonic->new(cache_dir => $cache_dir);

    $server->get('/get-test' => sub { 'GET response' });
    $server->post('/post-test' => sub { my ($req) = @_; 'POST:' . ($req->{body} // '') });
    $server->put('/put-test' => sub { 'PUT response' });
    $server->patch('/patch-test' => sub { 'PATCH response' });
    $server->del('/delete-test' => sub { 'DELETE response' });
    $server->get('/head-test' => sub { 'HEAD response' });
    $server->get('/options-test' => sub { 'OPTIONS response' });

    $server->compile();
    $server->run(port => $port, workers => 1);
});

# First wait for the listener to bind. Then do a request-level probe
# (a GET that must come back with the route's body) - the original
# bare "did it bind" wasn't enough because the kernel can accept()
# before the worker has finished registering its dispatch table.
my $bound = wait_for_port($port, { pid => $pid, log => $log, tries => 100 });
unless ($bound) {
    kill 'TERM', $pid;
    BAIL_OUT("server child failed to bind port $port (see diag above)");
}

my $ready = 0;
for (1..50) {
    my $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $port,
        Proto => 'tcp', Timeout => 1,
    );
    if ($sock) {
        print $sock "GET /get-test HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n";
        my $resp = do { local $/; <$sock> };
        close($sock);
        if ($resp && $resp =~ /GET response/) { $ready = 1; last; }
    }
    select undef, undef, undef, 0.1;
}
unless ($ready) {
    require HypersonicTest;
    HypersonicTest::diag_child_log($log);
    kill 'TERM', $pid;
}
ok($ready, 'Test server is running');

subtest 'gen_xs_get code' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA->gen_ua_registry($builder);
    Hypersonic::UA->gen_xs_get($builder);
    my $code = $builder->code();

    like($code, qr/xs_ua_get/, 'Function exists');
    like($code, qr/Usage:.*get/s, 'Has usage');
    like($code, qr/GET %s HTTP/s, 'Uses GET method in request');
};

subtest 'gen_xs_post code' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA->gen_ua_registry($builder);
    Hypersonic::UA->gen_xs_post($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_post/, 'Function exists');
    like($code, qr/"POST"/s, 'Uses POST method');
};

subtest 'gen_xs_put code' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA->gen_ua_registry($builder);
    Hypersonic::UA->gen_xs_put($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_put/, 'Function exists');
    like($code, qr/"PUT"/s, 'Uses PUT method');
};

subtest 'gen_xs_patch code' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA->gen_ua_registry($builder);
    Hypersonic::UA->gen_xs_patch($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_patch/, 'Function exists');
    like($code, qr/"PATCH"/s, 'Uses PATCH method');
};

subtest 'gen_xs_delete code' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA->gen_ua_registry($builder);
    Hypersonic::UA->gen_xs_delete($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_delete/, 'Function exists');
    like($code, qr/"DELETE"/s, 'Uses DELETE method');
};

subtest 'gen_xs_head code' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA->gen_ua_registry($builder);
    Hypersonic::UA->gen_xs_head($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_head/, 'Function exists');
    like($code, qr/"HEAD"/s, 'Uses HEAD method');
};

subtest 'gen_xs_options code' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA->gen_ua_registry($builder);
    Hypersonic::UA->gen_xs_options($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_options/, 'Function exists');
    like($code, qr/"OPTIONS"/s, 'Uses OPTIONS method');
};

subtest 'gen_xs_request code' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA->gen_ua_registry($builder);
    Hypersonic::UA->gen_xs_request($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_request/, 'Function exists');
    like($code, qr/method/s, 'Takes method parameter');
    like($code, qr/url/s, 'Takes url parameter');
};

kill('TERM', $pid);
waitpid($pid, 0);
system("rm -rf $cache_dir");

done_testing();
