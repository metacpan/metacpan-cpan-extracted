use strict;
use warnings;
use Test::More;
use Eshu;

plan tests => 6;

# 1. eval { ... } block
{
	my $input = <<'END';
eval {
die "oops";
};
END

	my $expected = <<'END';
eval {
	die "oops";
};
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'eval block');
}

# 2. Anonymous sub
{
	my $input = <<'END';
my $f = sub {
my $x = 1;
return $x;
};
END

	my $expected = <<'END';
my $f = sub {
	my $x = 1;
	return $x;
};
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'anonymous sub');
}

# 3. Chained method calls
{
	my $input = <<'END';
my $result = Foo->new({
name => 'bar',
age => 42,
});
END

	my $expected = <<'END';
my $result = Foo->new({
	name => 'bar',
	age => 42,
});
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'chained method call with hashref arg');
}

# 4. for loop with parens
{
	my $input = <<'END';
for my $x (@list) {
do_something($x);
}
END

	my $expected = <<'END';
for my $x (@list) {
	do_something($x);
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'for loop with parens');
}

# 5. Nested anonymous subs
{
	my $input = <<'END';
my $cb = sub {
my $inner = sub {
return 1;
};
$inner->();
};
END

	my $expected = <<'END';
my $cb = sub {
	my $inner = sub {
		return 1;
	};
	$inner->();
};
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'nested anonymous subs');
}

# 6. Complex hash of arrays
{
	my $input = <<'END';
my %h = (
a => [
1, 2, 3,
],
b => [
4, 5, 6,
],
);
END

	my $expected = <<'END';
my %h = (
	a => [
		1, 2, 3,
	],
	b => [
		4, 5, 6,
	],
);
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'hash of arrays nesting');
}
