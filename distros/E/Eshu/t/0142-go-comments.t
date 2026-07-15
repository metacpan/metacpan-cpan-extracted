use strict;
use warnings;
use Test::More;
use Eshu;

sub go { Eshu->indent_go($_[0]) }

# line comment inside a block
{
	my $input = <<'END';
func f() {
// this is a comment
x := 1
// another comment
}
END
	my $expected = <<'END';
func f() {
	// this is a comment
	x := 1
	// another comment
}
END
	is(go($input), $expected, 'line comments inside block indented');
}

# block comment
{
	my $input = <<'END';
func f() {
/* block comment
   spans lines */
x := 1
}
END
	my $expected = <<'END';
func f() {
	/* block comment
	   spans lines */
	x := 1
}
END
	is(go($input), $expected, 'block comment indented correctly');
}

# braces inside line comment must not affect depth
{
	my $input = <<'END';
func f() {
// if x { do something }
x := 1
}
END
	my $expected = <<'END';
func f() {
	// if x { do something }
	x := 1
}
END
	is(go($input), $expected, 'braces in line comment not parsed');
}

# braces inside block comment must not affect depth
{
	my $input = <<'END';
func f() {
/* { unclosed brace in comment */
x := 1
}
END
	my $expected = <<'END';
func f() {
	/* { unclosed brace in comment */
	x := 1
}
END
	is(go($input), $expected, 'braces in block comment not parsed');
}

done_testing;
