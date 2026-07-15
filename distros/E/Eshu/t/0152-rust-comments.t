use strict;
use warnings;
use Test::More;
use Eshu;

sub rs { Eshu->indent_rust($_[0]) }

# line comment with braces must not affect depth
{
	my $input = <<'END';
fn foo() {
let x = 1; // open { brace
let y = 2;
}
END
	my $expected = <<'END';
fn foo() {
	let x = 1; // open { brace
	let y = 2;
}
END
	is(rs($input), $expected, 'braces in line comment ignored');
}

# block comment with braces
{
	my $input = <<'END';
fn foo() {
/* { open brace in comment } */
let x = 1;
}
END
	my $expected = <<'END';
fn foo() {
	/* { open brace in comment } */
	let x = 1;
}
END
	is(rs($input), $expected, 'braces in block comment ignored');
}

# multi-line block comment
{
	my $input = <<'END';
fn foo() {
/*
* multi-line
* comment
*/
let x = 1;
}
END
	my $expected = <<'END';
fn foo() {
	/*
	* multi-line
	* comment
	*/
	let x = 1;
}
END
	is(rs($input), $expected, 'multi-line block comment indented');
}

# nested block comment /* /* */ */
{
	my $input = <<'END';
fn foo() {
/* outer /* inner */ still outer */
let x = 1;
}
END
	my $expected = <<'END';
fn foo() {
	/* outer /* inner */ still outer */
	let x = 1;
}
END
	is(rs($input), $expected, 'nested block comment');
}

# doc comment ///
{
	my $input = <<'END';
/// Computes the sum.
fn sum(a: i32, b: i32) -> i32 {
a + b
}
END
	my $expected = <<'END';
/// Computes the sum.
fn sum(a: i32, b: i32) -> i32 {
	a + b
}
END
	is(rs($input), $expected, 'doc comment /// at top level');
}

done_testing;
