use strict;
use warnings;
use Test::More;
use Eshu;

sub lua { Eshu->indent_lua($_[0]) }

# class-style module pattern
{
	my $input = <<'END';
local MyClass = {}
MyClass.__index = MyClass
function MyClass.new(x)
local self = setmetatable({}, MyClass)
self.x = x
return self
end
function MyClass:getX()
return self.x
end
return MyClass
END
	my $expected = <<'END';
local MyClass = {}
MyClass.__index = MyClass
function MyClass.new(x)
	local self = setmetatable({}, MyClass)
	self.x = x
	return self
end
function MyClass:getX()
	return self.x
end
return MyClass
END
	is(lua($input), $expected, 'class-style module pattern');
}

# nested if with for
{
	my $input = <<'END';
function process(items)
local result = {}
for i, v in ipairs(items) do
if v > 0 then
result[i] = v * 2
else
result[i] = 0
end
end
return result
end
END
	my $expected = <<'END';
function process(items)
	local result = {}
	for i, v in ipairs(items) do
		if v > 0 then
			result[i] = v * 2
		else
			result[i] = 0
		end
	end
	return result
end
END
	is(lua($input), $expected, 'nested if with for');
}

# blank lines preserved
{
	my $input = <<'END';
function f()
local x = 1

local y = 2
end
END
	my $expected = <<'END';
function f()
	local x = 1

	local y = 2
end
END
	is(lua($input), $expected, 'blank lines preserved');
}

done_testing;
