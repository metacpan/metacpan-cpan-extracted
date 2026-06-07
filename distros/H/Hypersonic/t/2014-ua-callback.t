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

my $port = 18881 + ($$ % 1000);
my $cache_dir = "_test_callback_cache_$$";

# spawn_server + wait_for_port give us the 60s minimum floor + child
# stderr capture; the old `for (1..10) { sleep(1) }` budget was too
# short for a cold JIT compile on a slow CPAN smoker.
my ($pid, $log) = spawn_server(sub {
    my $server = Hypersonic->new(cache_dir => $cache_dir);

    $server->get('/cb1' => sub { 'callback response 1' });
    $server->get('/cb2' => sub { 'callback response 2' });
    $server->post('/cb-post' => sub { my ($req) = @_; 'cb-posted:' . ($req->{body} // '') });

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
        print $sock "GET /cb1 HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n";
        my $resp = do { local $/; <$sock> };
        close($sock);
        if ($resp && $resp =~ /callback response 1/) { $ready = 1; last; }
    }
    select undef, undef, undef, 0.1;
}
unless ($ready) {
    HypersonicTest::diag_child_log($log);
    kill 'TERM', $pid;
}
ok($ready, 'Test server is running');

subtest 'gen_xs_request callback detection' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA->gen_ua_registry($builder);
    Hypersonic::UA->gen_xs_request($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_request/, 'Function exists');
    # Check for callback handling
    like($code, qr/SvROK|callback|SVt_PVCV/s, 'Has callback detection');
};

subtest 'gen_xs_get_async callback support' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA->gen_ua_registry($builder);
    Hypersonic::UA->gen_xs_get_async($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_get_async/, 'Function exists');
};

subtest 'Async callback storage' => sub {
    require XS::JIT::Builder;
    use Hypersonic::UA::Async;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->gen_async_context_registry($builder);
    my $code = $builder->code();
    
    like($code, qr/SV \*callback;/, 'AsyncContext has callback field');
    like($code, qr/SvREFCNT_dec\(ctx->callback\)/s, 'Callback refcount managed');
};

subtest 'Callback invocation pattern' => sub {
    require XS::JIT::Builder;
    use Hypersonic::UA::Async;
    my $builder = XS::JIT::Builder->new();
    Hypersonic::UA::Async->generate_c_code($builder, {});
    my $code = $builder->code();
    
    # Check callback is stored
    like($code, qr/ctx->callback/s, 'References callback field');
};

kill('TERM', $pid);
waitpid($pid, 0);
do { local $@; eval { require File::Path; File::Path::remove_tree($_, { safe => 1, error => \my $e }) for grep { -e $_ } glob(qq($cache_dir)); }; };

done_testing();
