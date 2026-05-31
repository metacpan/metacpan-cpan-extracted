use strict;
use warnings;
use Test::More;
use IO::Socket::INET;


use Hypersonic;
use Hypersonic::UA::Async;

plan skip_all => 'fork not available' unless $^O ne 'MSWin32';

my $port = 18882 + ($$ % 1000);
my $cache_dir = "_test_start_req_cache_$$";

my $pid = fork();
die "Fork failed: $!" unless defined $pid;

if ($pid == 0) {
    my $server = Hypersonic->new(cache_dir => $cache_dir);
    
    $server->get('/start-test' => sub { 'start request works' });
    $server->post('/start-post' => sub { my ($req) = @_; 'start-posted:' . ($req->{body} // '') });
    
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
        print $sock "GET /start-test HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n";
        my $resp = do { local $/; <$sock> };
        close($sock);
        if ($resp && $resp =~ /start request works/) { $ready = 1; last; }
    }
    sleep(1);
}
ok($ready, 'Test server is running');

subtest 'gen_xs_start_request URL parsing' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    Hypersonic::UA::Async->gen_xs_start_request($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_async_start_request/, 'Function exists');
    like($code, qr/strstr\(url, ":\/\/"\)/s, 'Parses scheme');
    like($code, qr/ctx->host/s, 'Extracts host');
    like($code, qr/ctx->port/s, 'Extracts port');
    like($code, qr/ctx->tls/s, 'Detects TLS');
};

subtest 'gen_xs_start_request HTTP request building' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    Hypersonic::UA::Async->gen_xs_start_request($builder);
    my $code = $builder->code();
    
    like($code, qr/ctx->request/s, 'Builds request buffer');
    like($code, qr/HTTP\/1\.1/s, 'Uses HTTP/1.1');
    like($code, qr/Host:/s, 'Adds Host header');
    like($code, qr/Content-Length/s, 'Handles Content-Length');
};

subtest 'gen_xs_start_request non-blocking socket' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    Hypersonic::UA::Async->gen_xs_start_request($builder);
    my $code = $builder->code();
    
    like($code, qr/socket\s*\(/s, 'Creates socket');
    like($code, qr/SOCK_NONBLOCK|O_NONBLOCK|fcntl/s, 'Sets non-blocking');
    like($code, qr/connect\s*\(/s, 'Initiates connect');
    like($code, qr/EINPROGRESS/s, 'Handles EINPROGRESS');
};

subtest 'gen_xs_start_request callback/future storage' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    Hypersonic::UA::Async->gen_xs_start_request($builder);
    my $code = $builder->code();
    
    like($code, qr/ctx->callback/s, 'Stores callback');
    like($code, qr/ctx->future_sv/s, 'Stores future SV');
    like($code, qr/SvROK|SVt_PVCV/s, 'Detects callback type');
};

subtest 'gen_xs_start_request error handling' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    Hypersonic::UA::Async->gen_xs_start_request($builder);
    my $code = $builder->code();
    
    like($code, qr/async_alloc_slot/s, 'Allocates slot');
    like($code, qr/slot < 0/s, 'Checks slot exhaustion');
    like($code, qr/async_free_slot/s, 'Has cleanup on error');
    like($code, qr/croak/s, 'Has error reporting');
};

kill('TERM', $pid);
waitpid($pid, 0);
do { local $@; eval { require File::Path; File::Path::remove_tree($_, { safe => 1, error => \my $e }) for grep { -e $_ } glob(qq($cache_dir)); }; };

done_testing();
