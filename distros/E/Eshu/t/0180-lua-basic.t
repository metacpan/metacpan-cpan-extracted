use strict;
use warnings;
use Test::More;
use Eshu;

sub lua { Eshu->indent_lua($_[0]) }

# simple if/then/end
{
	my $input = <<'END';
if x > 0 then
y = 1
end
END
	my $expected = <<'END';
if x > 0 then
	y = 1
end
END
	is(lua($input), $expected, 'if/then/end');
}

# while/do/end
{
	my $input = <<'END';
while x > 0 do
x = x - 1
end
END
	my $expected = <<'END';
while x > 0 do
	x = x - 1
end
END
	is(lua($input), $expected, 'while/do/end');
}

# function/end
{
	my $input = <<'END';
function greet(name)
print(name)
end
END
	my $expected = <<'END';
function greet(name)
	print(name)
end
END
	is(lua($input), $expected, 'function/end');
}

# nested blocks
{
	my $input = <<'END';
function f()
if x then
y = 1
end
end
END
	my $expected = <<'END';
function f()
	if x then
		y = 1
	end
end
END
	is(lua($input), $expected, 'nested function + if');
}

# repeat/until
{
	my $input = <<'END';
repeat
x = x + 1
until x > 10
END
	my $expected = <<'END';
repeat
	x = x + 1
until x > 10
END
	is(lua($input), $expected, 'repeat/until');
}

# do/end block
{
	my $input = <<'END';
do
local x = 1
end
END
	my $expected = <<'END';
do
	local x = 1
end
END
	is(lua($input), $expected, 'do/end block');
}

# for/do/end
{
	my $input = <<'END';
for i = 1, 10 do
print(i)
end
END
	my $expected = <<'END';
for i = 1, 10 do
	print(i)
end
END
	is(lua($input), $expected, 'for/do/end');
}

done_testing;
