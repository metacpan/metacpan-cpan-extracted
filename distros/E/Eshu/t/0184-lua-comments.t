use strict;
use warnings;
use Test::More;
use Eshu;

sub lua { Eshu->indent_lua($_[0]) }

# line comments don't affect depth
{
	my $input = <<'END';
function f()
-- this is a comment
x = 1
-- another comment
end
END
	my $expected = <<'END';
function f()
	-- this is a comment
	x = 1
	-- another comment
end
END
	is(lua($input), $expected, 'line comments indented correctly');
}

# keywords in comments don't affect depth
{
	my $input = <<'END';
function f()
-- if x then do end else end
x = 1
end
END
	my $expected = <<'END';
function f()
	-- if x then do end else end
	x = 1
end
END
	is(lua($input), $expected, 'keywords in line comment ignored');
}

# long comment spanning lines
{
	my $input = <<'END';
function f()
--[[
This is a
long comment
]]
x = 1
end
END
	my $expected = <<'END';
function f()
	--[[
This is a
long comment
]]
	x = 1
end
END
	is(lua($input), $expected, 'long comment spanning lines emitted verbatim');
}

done_testing;
