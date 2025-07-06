use strict;
use warnings;
use lib 'lib';
use Inline::Lua;

use Test::More;
use Test::Exception;

plan tests => 5;

# We need a non-sandboxed instance to test all error types,
# especially Fennel and stack traces.
my $lua = Inline::Lua->new(sandboxed => 0);

diag("--- Testing Error Handling ---");

# Test 1: Lua syntax error
my $lua_syntax_error = "function oops(";
dies_ok { $lua->eval($lua_syntax_error) } 'Dies on Lua syntax error';

# Test 2: Lua runtime error
my $lua_runtime_error = "local x = nil; x()";
throws_ok { $lua->eval($lua_runtime_error) } qr/stack traceback/, 'Dies with a stack traceback on Lua runtime error';

# Test 3: Fennel compile-time (syntax) error
my $fennel_syntax_error = '(let [x 1] (y))'; # `y` is not defined
dies_ok { $lua->eval_fennel($fennel_syntax_error) } 'Dies on Fennel compile-time error';

# Test 4: Fennel runtime error
my $fennel_runtime_error = '(error "this is a deliberate fennel error")';
throws_ok { $lua->eval_fennel($fennel_runtime_error) } qr/stack traceback/, 'Dies with a stack traceback on Fennel runtime error';

# Test 5: Makes sure some valid code does NOT die
lives_ok { $lua->eval_fennel('(+ 1 2)') } 'Valid code runs without dying';

done_testing();
