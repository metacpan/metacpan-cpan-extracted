use strict;
use warnings;
use Test::More;
use Eshu;

sub lua { Eshu->indent_lua($_[0]) }

# keywords in strings don't affect depth
{
	my $input = <<'END';
function f()
local s = "if x then end"
end
END
	my $expected = <<'END';
function f()
	local s = "if x then end"
end
END
	is(lua($input), $expected, 'keywords in double-quoted string ignored');
}

# single-quoted string
{
	my $input = <<'END';
function f()
local s = 'do end while'
end
END
	my $expected = <<'END';
function f()
	local s = 'do end while'
end
END
	is(lua($input), $expected, 'keywords in single-quoted string ignored');
}

# long string literal
{
	my $input = <<'END';
function f()
local s = [[
hello
world
]]
end
END
	my $expected = <<'END';
function f()
	local s = [[
hello
world
]]
end
END
	is(lua($input), $expected, 'long string literal spanning lines');
}

done_testing;
