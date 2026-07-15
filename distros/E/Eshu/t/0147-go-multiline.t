use strict;
use warnings;
use Test::More;
use Eshu;

sub go { Eshu->indent_go($_[0]) }

# multi-line function call
{
	my $input = <<'END';
func f() {
result := doSomething(
arg1,
arg2,
arg3,
)
_ = result
}
END
	my $expected = <<'END';
func f() {
	result := doSomething(
		arg1,
		arg2,
		arg3,
	)
	_ = result
}
END
	is(go($input), $expected, 'multi-line function call args');
}

# slice literal
{
	my $input = <<'END';
func f() {
nums := []int{
1,
2,
3,
}
_ = nums
}
END
	my $expected = <<'END';
func f() {
	nums := []int{
		1,
		2,
		3,
	}
	_ = nums
}
END
	is(go($input), $expected, 'multi-line slice literal');
}

# map literal
{
	my $input = <<'END';
func f() {
m := map[string]int{
"a": 1,
"b": 2,
}
_ = m
}
END
	my $expected = <<'END';
func f() {
	m := map[string]int{
		"a": 1,
		"b": 2,
	}
	_ = m
}
END
	is(go($input), $expected, 'multi-line map literal');
}

# multi-line if condition with parens
{
	my $input = <<'END';
func f(a, b, c bool) {
if (a &&
b &&
c) {
fmt.Println("all true")
}
}
END
	my $expected = <<'END';
func f(a, b, c bool) {
	if (a &&
		b &&
		c) {
		fmt.Println("all true")
	}
}
END
	is(go($input), $expected, 'multi-line if condition');
}

done_testing;
