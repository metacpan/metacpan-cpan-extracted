use Test::More;

no warnings 'once';

BEGIN { plan tests => 8 };

use Inline Lua	    => 'DATA',
	   Undef    => 'undefined value';

ok(1);
ok(take_num(42) == 43,				    "num");
ok(abs(take_num(42.42) - 42.42) - 1 < 0.1,	    "num");
ok(take_string("foo", "bar") eq "foobar",	    "string");
ok(! defined take_nil($Inline::Lua::Nil),	    "nil");
ok(take_nil(undef) eq "undefined value",	    "undef1");
ok(take_nil() eq "undefined value",		    "undef2");
ok(take_any("foo", "bar", "baz") eq "foobarbaz",    "list");

__END__
__Lua__
function take_num (a)
    return a+1
end

function take_string (a, b)
    return a..b
end

function take_nil (a)
    return a
end

function take_any (...)
    local a = ''
    local arg={...}
    for i = 1, #arg, 1 do
	a = a..arg[i]
    end
    return a
end
