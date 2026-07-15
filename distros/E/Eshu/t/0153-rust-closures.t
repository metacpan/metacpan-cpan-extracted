use strict;
use warnings;
use Test::More;
use Eshu;

sub rs { Eshu->indent_rust($_[0]) }

# closure with block body
{
	my $input = <<'END';
fn main() {
let double = |x| {
x * 2
};
}
END
	my $expected = <<'END';
fn main() {
	let double = |x| {
		x * 2
	};
}
END
	is(rs($input), $expected, 'closure with block body');
}

# iterator chain
{
	my $input = <<'END';
fn sum_evens(v: &[i32]) -> i32 {
v.iter()
.filter(|&&x| x % 2 == 0)
.sum()
}
END
	my $expected = <<'END';
fn sum_evens(v: &[i32]) -> i32 {
	v.iter()
	.filter(|&&x| x % 2 == 0)
	.sum()
}
END
	is(rs($input), $expected, 'iterator chain');
}

# if let
{
	my $input = <<'END';
fn foo(opt: Option<i32>) {
if let Some(x) = opt {
println!("{}", x);
}
}
END
	my $expected = <<'END';
fn foo(opt: Option<i32>) {
	if let Some(x) = opt {
		println!("{}", x);
	}
}
END
	is(rs($input), $expected, 'if let');
}

# while let
{
	my $input = <<'END';
fn drain(mut stack: Vec<i32>) {
while let Some(top) = stack.pop() {
println!("{}", top);
}
}
END
	my $expected = <<'END';
fn drain(mut stack: Vec<i32>) {
	while let Some(top) = stack.pop() {
		println!("{}", top);
	}
}
END
	is(rs($input), $expected, 'while let');
}

done_testing;
