use strict;
use warnings;
use Test::More;
use Eshu;

sub go { Eshu->indent_go($_[0]) }

# interpreted string with braces — braces inside strings must not affect depth
{
	my $input = <<'END';
func f() {
s := "hello {world}"
fmt.Println(s)
}
END
	my $expected = <<'END';
func f() {
	s := "hello {world}"
	fmt.Println(s)
}
END
	is(go($input), $expected, 'braces inside DQ string ignored');
}

# escaped quote inside string
{
	my $input = <<'END';
func f() {
s := "say \"hi\""
fmt.Println(s)
}
END
	my $expected = <<'END';
func f() {
	s := "say \"hi\""
	fmt.Println(s)
}
END
	is(go($input), $expected, 'escaped quote inside DQ string');
}

# raw string literal (backtick) — can contain anything
{
	my $input = <<'END';
func f() {
s := `hello
world`
fmt.Println(s)
}
END
	my $expected = <<'END';
func f() {
	s := `hello
world`
	fmt.Println(s)
}
END
	is(go($input), $expected, 'raw string (backtick) spans lines verbatim');
}

# raw string with braces — must not affect depth
{
	my $input = <<'END';
func f() {
q := `SELECT * FROM t WHERE id = {id}`
return q
}
END
	my $expected = <<'END';
func f() {
	q := `SELECT * FROM t WHERE id = {id}`
	return q
}
END
	is(go($input), $expected, 'braces inside raw string ignored');
}

# rune literal
{
	my $input = <<'END';
func f() {
r := '{'
fmt.Println(r)
}
END
	my $expected = <<'END';
func f() {
	r := '{'
	fmt.Println(r)
}
END
	is(go($input), $expected, 'brace inside rune literal ignored');
}

done_testing;
