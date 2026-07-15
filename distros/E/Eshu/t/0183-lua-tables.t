use strict;
use warnings;
use Test::More;
use Eshu;

sub lua { Eshu->indent_lua($_[0]) }

# simple table constructor
{
	my $input = <<'END';
local t = {
a = 1,
b = 2,
}
END
	my $expected = <<'END';
local t = {
	a = 1,
	b = 2,
}
END
	is(lua($input), $expected, 'table constructor');
}

# nested table
{
	my $input = <<'END';
local t = {
x = {
a = 1,
},
}
END
	my $expected = <<'END';
local t = {
	x = {
		a = 1,
	},
}
END
	is(lua($input), $expected, 'nested table constructor');
}

# table with function value
{
	my $input = <<'END';
local t = {
greet = function(name)
print(name)
end,
}
END
	my $expected = <<'END';
local t = {
	greet = function(name)
		print(name)
	end,
}
END
	is(lua($input), $expected, 'table with function value');
}

done_testing;
