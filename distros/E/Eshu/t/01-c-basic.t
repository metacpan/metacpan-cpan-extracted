use strict;
use warnings;
use Test::More;
use Eshu;

# Simple function with braces
{
	my $input = <<'END';
void foo() {
int x = 1;
if (x) {
x++;
}
return;
}
END

	my $expected = <<'END';
void foo() {
	int x = 1;
	if (x) {
		x++;
	}
	return;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'simple function with if block');
}

# Nested braces
{
	my $input = <<'END';
void foo() {
int x;
for (int i = 0; i < 10; i++) {
if (i > 5) {
x = i;
}
}
}
END

	my $expected = <<'END';
void foo() {
	int x;
	for (int i = 0; i < 10; i++) {
		if (i > 5) {
			x = i;
		}
	}
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'nested for/if blocks');
}

# Already correct indentation — idempotent
{
	my $input = <<'END';
void bar() {
	int a = 1;
	if (a) {
		a++;
	}
}
END

	my $got = Eshu->indent_c($input);
	is($got, $input, 'already correct is idempotent');
}

# Empty lines preserved
{
	my $input = <<'END';
    void baz() {

int x = 1;

}
END

	my $expected = <<'END';
void baz() {

	int x = 1;

}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'empty lines preserved');
}

# Parentheses nesting
{
	my $input = <<'END';
int x = foo(
1,
2,
3
);
END

	my $expected = <<'END';
int x = foo(
	1,
	2,
	3
);
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'paren nesting for function args');
}

# Multiple functions
{
	my $input = <<'END';
void a() {
x();
}

void b() {
y();
}
END

	my $expected = <<'END';
void a() {
	x();
}

void b() {
	y();
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'multiple functions');
}

# Spaces mode
{
	my $input = <<'END';
void foo() {
int x = 1;
}
END

	my $expected = <<'END';
void foo() {
    int x = 1;
}
END

	my $got = Eshu->indent_c($input, indent_char => ' ', indent_width => 4);
	is($got, $expected, 'spaces mode with width 4');
}

# Closing brace on same depth as opening construct
{
	my $input = <<'END';
struct foo {
int x;
int y;
};
END

	my $expected = <<'END';
struct foo {
	int x;
	int y;
};
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'struct with closing brace');
}

# Switch/case basic
{
	my $input = <<'END';
switch (x) {
case 1:
break;
case 2:
break;
default:
break;
}
END

	my $expected = <<'END';
switch (x) {
	case 1:
	break;
	case 2:
	break;
	default:
	break;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'switch/case basic');
}

done_testing();
