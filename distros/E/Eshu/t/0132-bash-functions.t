use strict;
use warnings;
use Test::More;
use Eshu;

# function keyword form
{
	my $input = <<'END';
function greet {
echo "Hello, $1"
}
END

	my $expected = <<'END';
function greet {
	echo "Hello, $1"
}
END

	is(Eshu->indent_bash($input), $expected, 'function keyword form');
}

# POSIX function form  name() { }
{
	my $input = <<'END';
greet() {
echo "Hello, $1"
}
END

	my $expected = <<'END';
greet() {
	echo "Hello, $1"
}
END

	is(Eshu->indent_bash($input), $expected, 'POSIX function form name() { }');
}

# function with if inside
{
	my $input = <<'END';
check_file() {
if [ -f "$1" ]; then
echo "exists"
else
echo "missing"
fi
}
END

	my $expected = <<'END';
check_file() {
	if [ -f "$1" ]; then
		echo "exists"
	else
		echo "missing"
	fi
}
END

	is(Eshu->indent_bash($input), $expected, 'function with if body');
}

# multiple functions
{
	my $input = <<'END';
foo() {
echo "foo"
}

bar() {
echo "bar"
}
END

	my $expected = <<'END';
foo() {
	echo "foo"
}

bar() {
	echo "bar"
}
END

	is(Eshu->indent_bash($input), $expected, 'multiple functions separated by blank lines');
}

done_testing;
