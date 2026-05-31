use strict;
use warnings;
use Test::More;
use IO::Socket::INET;


use Hypersonic;
use Hypersonic::UA::Async;

plan skip_all => 'fork not available' unless $^O ne 'MSWin32';

my $port = 18883 + ($$ % 1000);
my $cache_dir = "_test_poll_cache_$$";

my $pid = fork();
die "Fork failed: $!" unless defined $pid;

if ($pid == 0) {
    my $server = Hypersonic->new(cache_dir => $cache_dir);
    
    $server->get('/poll-test' => sub { 'poll response' });
    
    $server->compile();
    $server->run(port => $port, workers => 1);
    exit(0);
}

# Wait for server with retries
my $ready = 0;
for (1..10) {
    my $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp', Timeout => 1
    );
    if ($sock) {
        print $sock "GET /poll-test HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n";
        my $resp = do { local $/; <$sock> };
        close($sock);
        if ($resp && $resp =~ /poll response/) { $ready = 1; last; }
    }
    sleep(1);
}
ok($ready, 'Test server is running');

subtest 'gen_async_poll_one function signature' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    Hypersonic::UA::Async->gen_async_poll_one($builder);
    my $code = $builder->code();
    
    like($code, qr/static int async_poll_one\(int slot\)/s, 'Has correct signature');
    like($code, qr/return ASYNC_WAIT_NONE/s, 'Returns wait event');
};

subtest 'gen_async_poll_one CONNECTING state' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    Hypersonic::UA::Async->gen_async_poll_one($builder);
    my $code = $builder->code();
    
    like($code, qr/case ASYNC_STATE_CONNECTING/s, 'Has CONNECTING case');
    like($code, qr/ASYNC_WAIT_WRITE/s, 'Returns WRITE for connect');
};

subtest 'gen_async_poll_one TLS state' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    Hypersonic::UA::Async->gen_async_poll_one($builder);
    my $code = $builder->code();
    
    like($code, qr/case ASYNC_STATE_TLS/s, 'Has TLS case');
};

subtest 'gen_async_poll_one SENDING state' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    Hypersonic::UA::Async->gen_async_poll_one($builder);
    my $code = $builder->code();
    
    like($code, qr/case ASYNC_STATE_SENDING/s, 'Has SENDING case');
    like($code, qr/send\s*\(/s, 'Calls send');
    like($code, qr/ctx->request_sent/s, 'Tracks bytes sent');
    like($code, qr/ASYNC_STATE_RECEIVING/s, 'Transitions to RECEIVING');
};

subtest 'gen_async_poll_one RECEIVING state' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    Hypersonic::UA::Async->gen_async_poll_one($builder);
    my $code = $builder->code();
    
    like($code, qr/case ASYNC_STATE_RECEIVING/s, 'Has RECEIVING case');
    like($code, qr/recv\s*\(/s, 'Calls recv');
    like($code, qr/ctx->recv_buffer/s, 'Uses recv buffer');
    like($code, qr/realloc/s, 'Grows buffer if needed');
    like($code, qr/ASYNC_STATE_DONE/s, 'Transitions to DONE on EOF');
};

subtest 'gen_async_poll_one terminal states' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    Hypersonic::UA::Async->gen_async_poll_one($builder);
    my $code = $builder->code();
    
    like($code, qr/case ASYNC_STATE_DONE/s, 'Has DONE case');
    like($code, qr/case ASYNC_STATE_ERROR/s, 'Has ERROR case');
    like($code, qr/case ASYNC_STATE_CANCELLED/s, 'Has CANCELLED case');
};

subtest 'gen_xs_poll function' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    Hypersonic::UA::Async->gen_async_poll_one($builder);
    Hypersonic::UA::Async->gen_xs_poll($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_async_poll/, 'Function exists');
    like($code, qr/getsockopt.*SO_ERROR/s, 'Checks connect completion');
    like($code, qr/async_poll_one\(slot\)/s, 'Calls poll_one');
};

subtest 'gen_xs_poll connect completion' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    Hypersonic::UA::Async->gen_async_poll_one($builder);
    Hypersonic::UA::Async->gen_xs_poll($builder);
    my $code = $builder->code();
    
    like($code, qr/ASYNC_STATE_CONNECTING/s, 'Checks CONNECTING state');
    like($code, qr/ASYNC_STATE_SENDING/s, 'Transitions to SENDING');
    like($code, qr/ASYNC_STATE_ERROR/s, 'Has error state');
};

kill('TERM', $pid);
waitpid($pid, 0);
do { local $@; eval { require File::Path; File::Path::remove_tree($_, { safe => 1, error => \my $e }) for grep { -e $_ } glob(qq($cache_dir)); }; };

done_testing();
