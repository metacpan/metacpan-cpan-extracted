use strict;
use warnings;
use Test::More;

use lib 'lib';
use lib '../XS-JIT/blib/lib';
use lib '../XS-JIT/blib/arch';

use Hypersonic;

plan tests => 20;

# Test security hardening configuration options

# Test 1: Default security options
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_sec1');
    
    is($server->{max_connections}, 10000, 'Default max_connections is 10000');
    is($server->{max_request_size}, 8192, 'Default max_request_size is 8192');
    is($server->{keepalive_timeout}, 30, 'Default keepalive_timeout is 30');
    is($server->{recv_timeout}, 30, 'Default recv_timeout is 30');
    is($server->{drain_timeout}, 5, 'Default drain_timeout is 5');
}

# Test 2: Custom security options
{
    my $server = Hypersonic->new(
        cache_dir          => '_test_cache_sec2',
        max_connections    => 5000,
        max_request_size   => 16384,
        keepalive_timeout  => 60,
        recv_timeout       => 15,
        drain_timeout      => 10,
    );
    
    is($server->{max_connections}, 5000, 'Custom max_connections');
    is($server->{max_request_size}, 16384, 'Custom max_request_size');
    is($server->{keepalive_timeout}, 60, 'Custom keepalive_timeout');
}

# Test 3: Security headers - defaults
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_sec3');
    
    ok($server->{enable_security_headers}, 'Security headers enabled by default');
    is($server->{security_headers}{'X-Frame-Options'}, 'DENY', 'Default X-Frame-Options is DENY');
    is($server->{security_headers}{'X-Content-Type-Options'}, 'nosniff', 'Default X-Content-Type-Options is nosniff');
    is($server->{security_headers}{'X-XSS-Protection'}, '1; mode=block', 'Default X-XSS-Protection');
    is($server->{security_headers}{'Referrer-Policy'}, 'strict-origin-when-cross-origin', 'Default Referrer-Policy');
    ok(!defined $server->{security_headers}{'Strict-Transport-Security'}, 'HSTS not set without TLS');
}

# Test 4: Security headers - custom
{
    my $server = Hypersonic->new(
        cache_dir => '_test_cache_sec4',
        security_headers => {
            'X-Frame-Options' => 'SAMEORIGIN',
            'Content-Security-Policy' => "default-src 'self'",
        },
    );
    
    is($server->{security_headers}{'X-Frame-Options'}, 'SAMEORIGIN', 'Custom X-Frame-Options');
    is($server->{security_headers}{'Content-Security-Policy'}, "default-src 'self'", 'Custom CSP');
}

# Test 5: Security headers disabled
{
    my $server = Hypersonic->new(
        cache_dir => '_test_cache_sec5',
        enable_security_headers => 0,
    );
    
    ok(!$server->{enable_security_headers}, 'Security headers can be disabled');
}

# Test 6: Security headers in compiled response
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_sec6');
    $server->get('/test' => sub { 'OK' });
    $server->compile();
    
    my $resp = $server->dispatch(['GET', '/test']);
    ok($resp, 'Got response');
    like($resp, qr/X-Frame-Options: DENY/, 'Response includes X-Frame-Options');
    like($resp, qr/X-Content-Type-Options: nosniff/, 'Response includes X-Content-Type-Options');
}

# Cleanup
for my $i (1..6) {
    my $dir = "_test_cache_sec$i";
    system("rm -rf $dir") if -d $dir;
}

done_testing();
