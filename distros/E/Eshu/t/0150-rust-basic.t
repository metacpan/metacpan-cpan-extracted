use strict;
use warnings;
use Test::More;
use Eshu;

sub rs { Eshu->indent_rust($_[0]) }

# simple fn with braces
{
	my $input = <<'END';
fn main() {
let x = 1;
}
END
	my $expected = <<'END';
fn main() {
	let x = 1;
}
END
	is(rs($input), $expected, 'simple fn');
}

# nested blocks
{
	my $input = <<'END';
fn foo() {
if true {
let x = 1;
}
}
END
	my $expected = <<'END';
fn foo() {
	if true {
		let x = 1;
	}
}
END
	is(rs($input), $expected, 'nested blocks');
}

# match expression
{
	my $input = <<'END';
fn classify(x: i32) -> &'static str {
match x {
0 => "zero",
1 => "one",
_ => "other",
}
}
END
	my $expected = <<'END';
fn classify(x: i32) -> &'static str {
	match x {
		0 => "zero",
		1 => "one",
		_ => "other",
	}
}
END
	is(rs($input), $expected, 'match expression');
}

# struct definition
{
	my $input = <<'END';
struct Point {
x: f64,
y: f64,
}
END
	my $expected = <<'END';
struct Point {
	x: f64,
	y: f64,
}
END
	is(rs($input), $expected, 'struct at top level');
}

# impl block
{
	my $input = <<'END';
impl Point {
fn new(x: f64, y: f64) -> Self {
Point { x, y }
}
fn distance(&self) -> f64 {
(self.x * self.x + self.y * self.y).sqrt()
}
}
END
	my $expected = <<'END';
impl Point {
	fn new(x: f64, y: f64) -> Self {
		Point { x, y }
	}
	fn distance(&self) -> f64 {
		(self.x * self.x + self.y * self.y).sqrt()
	}
}
END
	is(rs($input), $expected, 'impl block with methods');
}

# closing brace on same line as body
{
	my $input = <<'END';
fn one() { 1 }
END
	my $expected = <<'END';
fn one() { 1 }
END
	is(rs($input), $expected, 'single-line fn');
}

# empty lines preserved
{
	my $input = <<'END';
fn foo() {
let a = 1;

let b = 2;
}
END
	my $expected = <<'END';
fn foo() {
	let a = 1;

	let b = 2;
}
END
	is(rs($input), $expected, 'empty line preserved');
}

done_testing;
