use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use IO::Socket::INET;
use HypersonicTest qw(spawn_server wait_for_port);


use Hypersonic;
use Hypersonic::UA;

# Skip if we can't fork
plan skip_all => 'fork not available' unless $^O ne 'MSWin32';

my $port = 18880 + ($$ % 1000);
my $cache_dir = "_test_run_cache_$$";

# Use spawn_server/wait_for_port so a cold JIT compile on slow CPAN
# smokers gets the full 60s minimum floor wait_for_port enforces,
# with child stderr capture for diag. Pre-0.18 the bare 50x0.1s
# probe was nowhere near enough for a cold compile.
my ($pid, $log) = spawn_server(sub {
    my $server = Hypersonic->new(cache_dir => $cache_dir);

    $server->get('/task/1' => sub { '{"task":1,"done":true}' });
    # Routes with runtime behavior (sleep) need dynamic => 1
    $server->get('/task/2' => sub { select(undef,undef,undef,0.05); '{"task":2,"done":true}' }, { dynamic => 1 });
    $server->get('/task/3' => sub { select(undef,undef,undef,0.1); '{"task":3,"done":true}' }, { dynamic => 1 });
    $server->get('/task/4' => sub { select(undef,undef,undef,0.15); '{"task":4,"done":true}' }, { dynamic => 1 });
    $server->get('/task/5' => sub { select(undef,undef,undef,0.2); '{"task":5,"done":true}' }, { dynamic => 1 });

    $server->get('/quick' => sub { 'quick' });
    $server->get('/slow' => sub { select(undef,undef,undef,0.3); 'slow' }, { dynamic => 1 });

    $server->compile();
    $server->run(port => $port, workers => 1);
});

my $bound = wait_for_port($port, { pid => $pid, log => $log, tries => 100 });
unless ($bound) {
    kill 'TERM', $pid;
    BAIL_OUT("server child failed to bind port $port (see diag above)");
}

# Parent - request-level probe to confirm dispatch is wired up
my $server_ready = 0;
for my $attempt (1..50) {
    my $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 0.2,
    );
    if ($sock) {
        print $sock "GET /quick HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n";
        my $resp = '';
        while (<$sock>) { $resp .= $_; }
        close($sock);
        if ($resp =~ /quick/) {
            $server_ready = 1;
            last;
        }
    }
    select(undef, undef, undef, 0.1);
}
unless ($server_ready) {
    HypersonicTest::diag_child_log($log);
    kill 'TERM', $pid;
}

ok($server_ready, 'Test server is running');

subtest 'gen_xs_run generates correct code' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    
    Hypersonic::UA->gen_xs_run($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_run/, 'Function name');
    like($code, qr/Usage:.*\$ua->run/, 'Usage message');
    
    # Loop structure
    like($code, qr/while.*iterations/, 'Has iteration loop');
    like($code, qr/max_iterations/, 'Has max iterations limit');
    
    # Pending check
    like($code, qr/call_method.*"pending"/, 'Checks pending count');
    like($code, qr/pending == 0.*break/, 'Breaks when no pending');
    
    # Tick call
    like($code, qr/call_method.*"tick"/, 'Calls tick');
};

subtest 'gen_xs_run_one generates correct code' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    
    Hypersonic::UA->gen_xs_run_one($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_run_one/, 'Function name');
    like($code, qr/Usage:.*\$ua->run_one.*\$future/, 'Usage includes future');
    like($code, qr/future_sv/, 'Has future parameter');
    
    # Polls until future ready
    like($code, qr/call_method.*"is_ready"/, 'Checks is_ready');
    like($code, qr/ready.*break/, 'Breaks when ready');
    
    # Gets result
    like($code, qr/call_method.*"get"/, 'Gets future result');
};

subtest 'gen_xs_tick generates correct code' => sub {
    require XS::JIT::Builder;
    require Hypersonic::UA::Async;
    require Hypersonic::Event;
    my $builder = XS::JIT::Builder->new();

    # Need async context registry first (includes event backend headers)
    my $backend_name = Hypersonic::Event->best_backend;
    my $event_backend = Hypersonic::Event->backend($backend_name);
    my $opts = { event_backend => $event_backend, event_backend_name => $backend_name };

    Hypersonic::UA::Async->gen_async_context_registry($builder, $opts);
    Hypersonic::UA::Async->gen_async_poll_one($builder);
    Hypersonic::UA::Async->gen_async_advance_state($builder);
    Hypersonic::UA::Async->gen_xs_tick($builder, $opts);
    my $code = $builder->code();

    like($code, qr/xs_ua_tick/, 'Function name');
    like($code, qr/Usage:.*\$ua->tick/, 'Usage message');
    # Implementation accesses self as HV for _async_pending tracking
    like($code, qr/SvRV\(self_sv\)|_async_pending/, 'Accesses UA self');
};

subtest 'gen_xs_pending generates correct code' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    
    # Need registry first
    Hypersonic::UA->gen_ua_registry($builder, 256);
    Hypersonic::UA->gen_xs_pending($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_pending/, 'Function name');
    like($code, qr/Usage:.*\$ua->pending/, 'Usage message');
    like($code, qr/pending/, 'Counts pending');
    like($code, qr/newSViv\(pending\)/, 'Returns pending count');
};

subtest 'gen_xs_parallel generates correct code' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    
    Hypersonic::UA->gen_xs_parallel($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_parallel/, 'Function name');
    like($code, qr/Usage:.*\$ua->parallel.*\@futures/, 'Usage includes futures');
    
    # Collects futures
    like($code, qr/AV \*futures = newAV/, 'Creates futures array');
    like($code, qr/av_push\(futures/, 'Pushes futures');
    
    # Creates combined future
    like($code, qr/Hypersonic::Future::needs_all/, 'Uses needs_all');
    
    # Runs to completion
    like($code, qr/call_method.*"run_one"/, 'Calls run_one');
};

subtest 'gen_xs_race generates correct code' => sub {
    require XS::JIT::Builder;
    my $builder = XS::JIT::Builder->new();
    
    Hypersonic::UA->gen_xs_race($builder);
    my $code = $builder->code();
    
    like($code, qr/xs_ua_race/, 'Function name');
    like($code, qr/Usage:.*\$ua->race.*\@futures/, 'Usage includes futures');
    
    # Collects futures
    like($code, qr/AV \*futures = newAV/, 'Creates futures array');
    
    # Creates race future
    like($code, qr/Hypersonic::Future::needs_any/, 'Uses needs_any');
    
    # Runs to completion
    like($code, qr/call_method.*"run_one"/, 'Calls run_one');
};

subtest 'Run methods work together' => sub {
    require XS::JIT::Builder;
    require Hypersonic::UA::Async;
    require Hypersonic::Event;
    my $builder = XS::JIT::Builder->new();

    # Get event backend for tick generation
    my $backend_name = Hypersonic::Event->best_backend;
    my $event_backend = Hypersonic::Event->backend($backend_name);
    my $opts = { event_backend => $event_backend, event_backend_name => $backend_name };

    # Generate all run-related methods
    Hypersonic::UA->gen_ua_registry($builder, 256);
    # tick is now in Async.pm and needs async context registry first
    Hypersonic::UA::Async->gen_async_context_registry($builder, $opts);
    Hypersonic::UA::Async->gen_async_poll_one($builder);
    Hypersonic::UA::Async->gen_async_advance_state($builder);
    Hypersonic::UA::Async->gen_xs_tick($builder, $opts);
    Hypersonic::UA->gen_xs_pending($builder);
    Hypersonic::UA->gen_xs_run($builder);
    Hypersonic::UA->gen_xs_run_one($builder);
    Hypersonic::UA->gen_xs_parallel($builder);
    Hypersonic::UA->gen_xs_race($builder);

    my $code = $builder->code();

    # All functions present
    like($code, qr/xs_ua_tick/, 'tick present');
    like($code, qr/xs_ua_pending/, 'pending present');
    like($code, qr/xs_ua_run\b/, 'run present');
    like($code, qr/xs_ua_run_one/, 'run_one present');
    like($code, qr/xs_ua_parallel/, 'parallel present');
    like($code, qr/xs_ua_race/, 'race present');
};

# Cleanup
kill('TERM', $pid);
waitpid($pid, 0);
do { local $@; eval { require File::Path; File::Path::remove_tree($_, { safe => 1, error => \my $e }) for grep { -e $_ } glob(qq($cache_dir)); }; };

done_testing();
