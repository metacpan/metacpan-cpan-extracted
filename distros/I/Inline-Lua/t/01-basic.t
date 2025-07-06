use strict;
use warnings;
use lib 'lib';
use Inline::Lua;

use Test::More;
use Test::Exception;
use Data::Dumper;

# REMINDER: MUST be 13
plan tests => 13;

# --- Test Sandboxed (Default) Instance ---
diag("--- Testing Sandboxed Instance (Default) ---");

my $lua_safe;
lives_ok { $lua_safe = Inline::Lua->new() } 'Can create a new sandboxed object';
isa_ok($lua_safe, 'Inline::Lua');

# This test will only run if the object was created successfully.
SKIP: {
    skip "Skipping tests because sandboxed object creation failed", 3 unless $lua_safe;
    is($lua_safe->eval('return 10 + 5'), 15, 'Sandboxed: Simple Lua addition works');
    is($lua_safe->eval('return "hello"'), "hello", 'Sandboxed: String returns correctly');
    dies_ok { $lua_safe->eval_fennel('(+ 1 2)') } 'Sandboxed: eval_fennel dies as expected';
};

# --- Test Non-Sandboxed Instance ---
diag("--- Testing Non-Sandboxed Instance ---");

my $lua_unsafe;
lives_ok { $lua_unsafe = Inline::Lua->new(sandboxed => 0) } 'Can create a non-sandboxed object';
isa_ok($lua_unsafe, 'Inline::Lua');

SKIP: {
    skip "Skipping tests because non-sandboxed object creation failed", 6 unless $lua_unsafe;
    is($lua_unsafe->eval_fennel('(+ 20 5)'), 25, 'Non-sandboxed: Simple Fennel addition works');

    my $data = $lua_unsafe->eval(q{
        return {
            message = "Hello from Lua",
            items = { 1, 2, "three" },
            nested = { is_supported = true }
        }
    });

    is($data->{message}, 'Hello from Lua', 'Non-sandboxed: Hash string value is correct');
    is_deeply($data->{items}, [1, 2, 'three'], 'Non-sandboxed: Array value is correct');
    is($data->{nested}->{is_supported}, 1, 'Non-sandboxed: Nested boolean value is correct');

    # Test DESTROY
    {
        my $temp_lua = Inline::Lua->new();
        ok(ref($temp_lua), "Temporary object created for DESTROY test");
    }
    pass("Object went out of scope without crashing (DESTROY was called)");
};

done_testing();
