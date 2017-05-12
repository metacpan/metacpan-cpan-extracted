use Test::More;

BEGIN { plan tests => 5 };

use Inline Lua	    => 'DATA',
	   Undef    => sub { return shift };

ok(1);

ok(fib()->(1)  == 1,					    "fib(1)");
ok(fib()->(11) == 144,					    "fib(11)");
ok(simple_closure(42) == 42,				    "simple closure");

my @a = return_list(sub { return 1, 2, 3 });
is_deeply(\@a, [1,2,3],					    "closure returns list");

__END__
__Lua__
function fib ()
    --return a Fibonacci number generator
    local f
    f = function (n)
	if n < 2 then return 1 end
	return f(n-2) + f(n-1)
    end
    return f
end

function simple_closure (a, f)
    return f(a)
end

function return_list (f)
    return f()
end
    
