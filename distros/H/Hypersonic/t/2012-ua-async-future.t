use strict;
use warnings;
use Test::More;
use IO::Socket::INET;


use Hypersonic;
use Hypersonic::UA;

plan skip_all => 'fork not available' unless $^O ne 'MSWin32';

my $port = 18879 + ($$ % 1000);
my $cache_dir = "_test_async_future_cache_$$";

my $pid = fork();
die "Fork failed: $!" unless defined $pid;

if ($pid == 0) {
    my $server = Hypersonic->new(cache_dir => $cache_dir);
    
    $server->get('/async1' => sub { 'async response 1' });
    $server->get('/async2' => sub { 'async response 2' });
    $server->post('/async-post' => sub { my ($req) = @_; 'posted:' . ($req->{body} // '') });
    
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
        print $sock "GET /async1 HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n";
        my $resp = do { local $/; <$sock> };
        close($sock);
        if ($resp && $resp =~ /async response 1/) { $ready = 1; last; }
    }
    sleep(1);
}
ok($ready, 'Test server is running');

subtest 'gen_xs_get_async code' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA->gen_ua_registry($builder);
    Hypersonic::UA->gen_xs_get_async($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_get_async/, 'Function exists');
    like($code, qr/future/si, 'References future');
};

subtest 'gen_xs_post_async code' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA->gen_ua_registry($builder);
    Hypersonic::UA->gen_xs_post_async($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_post_async/, 'Function exists');
};

subtest 'gen_xs_put_async code' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA->gen_ua_registry($builder);
    Hypersonic::UA->gen_xs_put_async($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_put_async/, 'Function exists');
};

subtest 'gen_xs_delete_async code' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA->gen_ua_registry($builder);
    Hypersonic::UA->gen_xs_delete_async($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_delete_async/, 'Function exists');
};

subtest 'gen_xs_request_async code' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA->gen_ua_registry($builder);
    Hypersonic::UA->gen_xs_request_async($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_request_async/, 'Function exists');
    like($code, qr/method/si, 'Takes method parameter');
};

subtest 'Future integration patterns' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    # Note: generate_c_code takes ($builder, $opts, $analysis) - need analysis with needs_async
    my $analysis = { needs_async => 1 };
    Hypersonic::UA->generate_c_code($builder, {}, $analysis);
    my $code = $builder->code();

    # Check for future-related patterns
    like($code, qr/future/si, 'Has future references');
};

kill('TERM', $pid);
waitpid($pid, 0);
do { local $@; eval { require File::Path; File::Path::remove_tree($_, { safe => 1, error => \my $e }) for grep { -e $_ } glob(qq($cache_dir)); }; };

done_testing();
