use strict;
use warnings;
use Test::More;

use lib 'lib';
use lib '../XS-JIT/blib/lib';
use lib '../XS-JIT/blib/arch';

use Hypersonic;

plan tests => 12;

# Test custom status codes - static routes

# Test 1: Hashref response with custom status
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_status1');
    $server->get('/created' => sub {
        return { status => 201, body => '{"id":1}' };
    });
    $server->get('/redirect' => sub {
        return { 
            status => 301, 
            headers => { 'Location' => '/new-path' },
            body => 'Moved' 
        };
    });
    $server->compile();
    
    my $resp1 = $server->dispatch(['GET', '/created', '', 1, 0]);
    like($resp1, qr/HTTP\/1\.1 201 Created/, 'Custom status 201 in response');
    like($resp1, qr/\{"id":1\}/, 'Body included with custom status');
    
    my $resp2 = $server->dispatch(['GET', '/redirect', '', 1, 0]);
    like($resp2, qr/HTTP\/1\.1 301 Moved Permanently/, 'Custom status 301 in response');
    like($resp2, qr/Location: \/new-path/, 'Custom header included');
}

# Test 2: Arrayref response [status, headers, body]
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_status2');
    $server->get('/array-style' => sub {
        return [202, { 'X-Custom' => 'value' }, '{"accepted":true}'];
    });
    $server->compile();
    
    my $resp = $server->dispatch(['GET', '/array-style', '', 1, 0]);
    like($resp, qr/HTTP\/1\.1 202 Accepted/, 'Arrayref style - status 202');
    like($resp, qr/X-Custom: value/, 'Arrayref style - custom header');
    like($resp, qr/\{"accepted":true\}/, 'Arrayref style - body');
}

# Test 3: Various status codes
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_status3');
    $server->get('/bad-request' => sub { return { status => 400, body => 'Bad' } });
    $server->get('/forbidden' => sub { return { status => 403, body => 'Forbidden' } });
    $server->get('/not-found' => sub { return { status => 404, body => 'Not Found' } });
    $server->get('/server-error' => sub { return { status => 500, body => 'Error' } });
    $server->compile();
    
    my $resp400 = $server->dispatch(['GET', '/bad-request', '', 1, 0]);
    like($resp400, qr/HTTP\/1\.1 400 Bad Request/, 'Status 400');
    
    my $resp403 = $server->dispatch(['GET', '/forbidden', '', 1, 0]);
    like($resp403, qr/HTTP\/1\.1 403 Forbidden/, 'Status 403');
    
    my $resp404 = $server->dispatch(['GET', '/not-found', '', 1, 0]);
    like($resp404, qr/HTTP\/1\.1 404 Not Found/, 'Status 404');
    
    my $resp500 = $server->dispatch(['GET', '/server-error', '', 1, 0]);
    like($resp500, qr/HTTP\/1\.1 500 Internal Server Error/, 'Status 500');
}

# Test 4: Default status is 200
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_status4');
    $server->get('/default' => sub { return { body => 'OK' } });
    $server->compile();
    
    my $resp = $server->dispatch(['GET', '/default', '', 1, 0]);
    like($resp, qr/HTTP\/1\.1 200 OK/, 'Default status is 200');
}

# Cleanup
for my $i (1..4) {
    my $dir = "_test_cache_status$i";
    system("rm -rf $dir") if -d $dir;
}

done_testing();
