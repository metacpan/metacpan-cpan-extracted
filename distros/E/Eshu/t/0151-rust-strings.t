use strict;
use warnings;
use Test::More;
use Eshu;

sub rs { Eshu->indent_rust($_[0]) }

# string with braces must not affect depth
{
	my $input = <<'END';
fn greet() {
let s = "hello {world}";
let t = "open { brace";
}
END
	my $expected = <<'END';
fn greet() {
	let s = "hello {world}";
	let t = "open { brace";
}
END
	is(rs($input), $expected, 'braces inside string ignored');
}

# raw string r"..." with brace
{
	my $input = <<'END';
fn raw() {
let s = r"raw { string }";
let x = 1;
}
END
	my $expected = <<'END';
fn raw() {
	let s = r"raw { string }";
	let x = 1;
}
END
	is(rs($input), $expected, 'raw string r"..." braces ignored');
}

# raw string with hashes r#"..."#
{
	my $input = <<'END';
fn hashed() {
let s = r#"raw with "quotes" inside"#;
let x = 1;
}
END
	my $expected = <<'END';
fn hashed() {
	let s = r#"raw with "quotes" inside"#;
	let x = 1;
}
END
	is(rs($input), $expected, 'raw string r#"..."# braces ignored');
}

# char literal with brace (not a real brace in Rust but test escape)
{
	my $input = <<'END';
fn chars() {
let c = '\'';
let d = '\n';
let x = 1;
}
END
	my $expected = <<'END';
fn chars() {
	let c = '\'';
	let d = '\n';
	let x = 1;
}
END
	is(rs($input), $expected, 'char literal with escape');
}

# lifetime annotation: 'a must not be treated as string
{
	my $input = <<'END';
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
if x.len() > y.len() {
x
} else {
y
}
}
END
	my $expected = <<'END';
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
	if x.len() > y.len() {
		x
	} else {
		y
	}
}
END
	is(rs($input), $expected, 'lifetime annotation ignored for depth');
}

# byte string b"..."
{
	my $input = <<'END';
fn bytes() {
let b = b"hello { world }";
let x = 1;
}
END
	my $expected = <<'END';
fn bytes() {
	let b = b"hello { world }";
	let x = 1;
}
END
	is(rs($input), $expected, 'byte string b"..." braces ignored');
}

done_testing;
