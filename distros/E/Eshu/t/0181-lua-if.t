use strict;
use warnings;
use Test::More;
use Eshu;

sub lua { Eshu->indent_lua($_[0]) }

# if/elseif/else/end
{
	my $input = <<'END';
if x == 1 then
a()
elseif x == 2 then
b()
else
c()
end
END
	my $expected = <<'END';
if x == 1 then
	a()
elseif x == 2 then
	b()
else
	c()
end
END
	is(lua($input), $expected, 'if/elseif/else/end');
}

# if/else/end
{
	my $input = <<'END';
if ok then
return 1
else
return 0
end
END
	my $expected = <<'END';
if ok then
	return 1
else
	return 0
end
END
	is(lua($input), $expected, 'if/else/end');
}

# multiple elseif
{
	my $input = <<'END';
if a then
x = 1
elseif b then
x = 2
elseif c then
x = 3
else
x = 4
end
END
	my $expected = <<'END';
if a then
	x = 1
elseif b then
	x = 2
elseif c then
	x = 3
else
	x = 4
end
END
	is(lua($input), $expected, 'multiple elseif');
}

done_testing;
