use strict;
use warnings;
use Test::More;
use Eshu;

sub lua { Eshu->indent_lua($_[0]) }

# local function
{
	my $input = <<'END';
local function add(a, b)
return a + b
end
END
	my $expected = <<'END';
local function add(a, b)
	return a + b
end
END
	is(lua($input), $expected, 'local function');
}

# method-style function
{
	my $input = <<'END';
function MyClass:method(x)
self.value = x
end
END
	my $expected = <<'END';
function MyClass:method(x)
	self.value = x
end
END
	is(lua($input), $expected, 'method-style function');
}

# nested functions
{
	my $input = <<'END';
function outer()
function inner()
return 1
end
return inner()
end
END
	my $expected = <<'END';
function outer()
	function inner()
		return 1
	end
	return inner()
end
END
	is(lua($input), $expected, 'nested functions');
}

# anonymous function assigned
{
	my $input = <<'END';
local f = function(x)
return x * 2
end
END
	my $expected = <<'END';
local f = function(x)
	return x * 2
end
END
	is(lua($input), $expected, 'anonymous function assigned');
}

done_testing;
