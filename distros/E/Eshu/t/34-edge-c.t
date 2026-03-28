use strict;
use warnings;
use Test::More;
use Eshu;

plan tests => 6;

# 1. Multiline macro continuation
{
	my $input = <<'END';
#define FOO(x) \
    do { \
        bar(x); \
    } while(0)
END

	my $expected = <<'END';
#define FOO(x) \
do { \
	bar(x); \
} while(0)
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'multiline macro continuation re-indents body');
}

# 2. Struct/enum initializers with braces
{
	my $input = <<'END';
int arr[] = {
1, 2, 3,
4, 5, 6,
};
END

	my $expected = <<'END';
int arr[] = {
	1, 2, 3,
	4, 5, 6,
};
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'struct/enum initializer braces');
}

# 3. Nested struct initializers
{
	my $input = <<'END';
struct s data[] = {
{ 1, "a" },
{ 2, "b" },
};
END

	my $expected = <<'END';
struct s data[] = {
	{ 1, "a" },
	{ 2, "b" },
};
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'nested struct initializers');
}

# 4. Switch/case: case at same depth as switch body
{
	my $input = <<'END';
void foo() {
switch (x) {
case 1:
bar();
break;
case 2:
baz();
break;
default:
qux();
}
}
END

	my $expected = <<'END';
void foo() {
	switch (x) {
		case 1:
		bar();
		break;
		case 2:
		baz();
		break;
		default:
		qux();
	}
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'switch/case indentation');
}

# 5. Labels (goto) stay at brace depth
{
	my $input = <<'END';
void foo() {
int x = 0;
retry:
x++;
if (x < 3) goto retry;
}
END

	my $expected = <<'END';
void foo() {
	int x = 0;
	retry:
	x++;
	if (x < 3) goto retry;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'goto labels at function body depth');
}

# 6. Mixed preprocessor nesting with code
{
	my $input = <<'END';
void foo() {
#ifdef BAR
int x = 1;
#else
int x = 2;
#endif
return x;
}
END

	my $expected = <<'END';
void foo() {
#ifdef BAR
	int x = 1;
#else
	int x = 2;
#endif
	return x;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'preprocessor inside function body');
}
