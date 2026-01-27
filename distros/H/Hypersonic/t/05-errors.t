use strict;
use warnings;
use Test::More;

use lib 'lib';
use lib '../XS-JIT/blib/lib';
use lib '../XS-JIT/blib/arch';

use Hypersonic;

# Test error conditions

# Test 1: Path must start with /
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_err1');
    eval { $server->get('no-slash' => sub { 'test' }) };
    like($@, qr/must start with \//, 'Path without / rejected');
}

# Test 2: Handler must be code ref
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_err2');
    eval { $server->get('/test' => 'not a sub') };
    like($@, qr/must be a code ref/, 'Non-coderef handler rejected');
}

# Test 3: Handler returning hashref with body works (custom status codes)
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_err3');
    $server->get('/test' => sub { return { status => 201, body => 'created' } });
    eval { $server->compile() };
    is($@, '', 'Hashref response with body is valid (custom status codes)');
}

# Test 4: Handler must return defined value
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_err4');
    $server->get('/test' => sub { return undef });
    eval { $server->compile() };
    like($@, qr/must return a string/, 'Undef response rejected');
}

# Test 5: No routes defined
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_err5');
    eval { $server->compile() };
    like($@, qr/No routes defined/, 'Empty routes rejected');
}

# Test 6: Already compiled
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_err6');
    $server->get('/test' => sub { 'OK' });
    $server->compile();
    eval { $server->compile() };
    like($@, qr/Already compiled/, 'Double compile rejected');
}

# Test 7: Must compile before dispatch
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_err7');
    $server->get('/test' => sub { 'OK' });
    eval { $server->dispatch(['GET', '/test', '', 1, 0]) };
    like($@, qr/Must call compile/, 'Dispatch before compile rejected');
}

# Test 8: Must compile before run
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_err8');
    $server->get('/test' => sub { 'OK' });
    eval { $server->run(port => 9999) };
    like($@, qr/Must call compile/, 'Run before compile rejected');
}

# Cleanup
system("rm -rf _test_cache_err*");

done_testing();
