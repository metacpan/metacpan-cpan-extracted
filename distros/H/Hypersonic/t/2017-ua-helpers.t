use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use IO::Socket::INET;
use HypersonicTest qw(spawn_server wait_for_port);


use Hypersonic;
use Hypersonic::UA::Async;

plan skip_all => 'fork not available' unless $^O ne 'MSWin32';

my $port = 18884 + ($$ % 1000);
my $cache_dir = "_test_helpers_cache_$$";

# spawn_server + wait_for_port give us the 60s minimum floor + child
# stderr capture; the old `for (1..10) { sleep(1) }` budget was too
# short for a cold JIT compile on a slow CPAN smoker.
my ($pid, $log) = spawn_server(sub {
    my $server = Hypersonic->new(cache_dir => $cache_dir);

    $server->get('/helper-test' => sub { 'helper works' });

    $server->compile();
    $server->run(port => $port, workers => 1);
});

my $bound = wait_for_port($port, { pid => $pid, log => $log, tries => 100 });
unless ($bound) {
    kill 'TERM', $pid;
    BAIL_OUT("server child failed to bind port $port (see diag above)");
}

my $ready = 0;
for (1..50) {
    my $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp', Timeout => 1,
    );
    if ($sock) {
        print $sock "GET /helper-test HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n";
        my $resp = do { local $/; <$sock> };
        close($sock);
        if ($resp && $resp =~ /helper works/) { $ready = 1; last; }
    }
    select undef, undef, undef, 0.1;
}
unless ($ready) {
    HypersonicTest::diag_child_log($log);
    kill 'TERM', $pid;
}
ok($ready, 'Test server is running');

subtest 'gen_xs_get_fd' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    Hypersonic::UA::Async->gen_xs_get_fd($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_async_get_fd/, 'Function exists');
    like($code, qr/async_registry\[slot\]\.fd/s, 'Accesses fd');
};

subtest 'gen_xs_get_events' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    Hypersonic::UA::Async->gen_async_poll_one($builder);
    Hypersonic::UA::Async->gen_xs_get_events($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_async_get_events/, 'Function exists');
    like($code, qr/async_poll_one\(slot\)/s, 'Calls poll_one');
};

subtest 'gen_xs_cancel' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    Hypersonic::UA::Async->gen_xs_cancel($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_async_cancel/, 'Function exists');
    like($code, qr/ASYNC_STATE_CANCELLED/s, 'Sets CANCELLED state');
};

subtest 'gen_xs_cleanup' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    Hypersonic::UA::Async->gen_xs_cleanup($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_async_cleanup/, 'Function exists');
    like($code, qr/async_free_slot\(slot\)/s, 'Calls free_slot');
};

subtest 'gen_xs_get_future' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    Hypersonic::UA::Async->gen_xs_get_future($builder);
    my $code = $builder->code();

    like($code, qr/xs_async_get_future/, 'Function exists');
    like($code, qr/async_registry\[slot\]\.future_sv/s, 'Accesses future_sv');
};

subtest 'async_free_slot cleanup' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    my $code = $builder->code();
    
    like($code, qr/static void async_free_slot\(int slot\)/s, 'Function signature');
    like($code, qr/close\(ctx->fd\)/s, 'Closes fd');
    like($code, qr/free\(ctx->host\)/s, 'Frees host');
    like($code, qr/free\(ctx->request\)/s, 'Frees request');
    like($code, qr/free\(ctx->recv_buffer\)/s, 'Frees recv_buffer');
    like($code, qr/SvREFCNT_dec\(ctx->callback\)/s, 'Decrements callback refcount');
    like($code, qr/memset\(ctx, 0/s, 'Zeroes context');
};

subtest 'async_alloc_slot' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    my $code = $builder->code();

    like($code, qr/static int async_alloc_slot\(void\)/s, 'Function signature');
    like($code, qr/async_registry\[i\]\.in_use/s, 'Checks in_use');
    like($code, qr/async_registry\[i\]\.fd = -1/s, 'Initializes fd to -1');
    like($code, qr/async_registry\[i\]\.future_sv = NULL/s, 'Initializes future_sv to NULL');
    like($code, qr/return i/s, 'Returns slot index');
    like($code, qr/return -1/s, 'Returns -1 when full');
};

kill('TERM', $pid);
waitpid($pid, 0);
do { local $@; eval { require File::Path; File::Path::remove_tree($_, { safe => 1, error => \my $e }) for grep { -e $_ } glob(qq($cache_dir)); }; };

done_testing();
