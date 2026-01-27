use strict;
use warnings;
use Test::More;

use lib 'lib';
use lib '../XS-JIT/blib/lib';
use lib '../XS-JIT/blib/arch';

use Hypersonic;

# Test that handlers run at COMPILE time, not request time
# This is the core magic of Hypersonic

my $call_count = 0;
my $compile_time_value;

my $server = Hypersonic->new(cache_dir => '_test_cache_compile');

# This handler increments a counter and captures a timestamp
$server->get('/counter' => sub {
    $call_count++;
    $compile_time_value = time();
    return qq({"calls":$call_count,"time":$compile_time_value});
});

# Before compile - handler hasn't run
is($call_count, 0, 'Handler not called before compile');

# Compile routes - this runs the handler ONCE
$server->compile();

is($call_count, 1, 'Handler called exactly once at compile time');
ok($compile_time_value, 'Compile time value captured');

# Dispatch multiple requests - handler should NOT run again
for my $i (1..10) {
    my $resp = $server->dispatch(['GET', '/counter', '', 1, 0]);
    ok(defined $resp, "Request $i got response");
}

# Call count should still be 1 - handlers don't run per-request
is($call_count, 1, 'Handler still called only once after 10 requests');

# The response should contain the compile-time values
my $resp = $server->dispatch(['GET', '/counter', '', 1, 0]);
like($resp, qr/"calls":1/, 'Response has call count from compile time');
like($resp, qr/"time":$compile_time_value/, 'Response has timestamp from compile time');

# Test that response is truly baked in
sleep(1);  # Wait a second
my $resp2 = $server->dispatch(['GET', '/counter', '', 1, 0]);
like($resp2, qr/"time":$compile_time_value/, 'Timestamp unchanged - response is baked');

# Clean up
system("rm -rf _test_cache_compile");

done_testing();
