use strict;
use warnings;
use Test::More tests => 7;
use Eshu;

# Basic qw()
{
	my $input = <<'END';
sub foo {
my @list = qw(
foo
bar
baz
);
my $x = 1;
}
END

	my $expected = <<'END';
sub foo {
	my @list = qw(
		foo
		bar
		baz
	);
	my $x = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'qw() multi-line');
}

# qw with braces in content
{
	my $input = <<'END';
sub foo {
my @list = qw(hello{world});
my $x = 1;
}
END

	my $expected = <<'END';
sub foo {
	my @list = qw(hello{world});
	my $x = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'qw() single-line with braces in content');
}

# qq{} with braces
{
	my $input = <<'END';
sub foo {
my $x = qq{hello { world }};
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = qq{hello { world }};
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'qq{} with nested braces');
}

# q{} with braces
{
	my $input = <<'END';
sub foo {
my $x = q{hello { world }};
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = q{hello { world }};
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'q{} with nested braces');
}

# qw with different delimiters
{
	my $input = <<'END';
sub foo {
my @a = qw/foo bar/;
my @b = qw[baz qux];
my @c = qw<one two>;
}
END

	my $expected = <<'END';
sub foo {
	my @a = qw/foo bar/;
	my @b = qw[baz qux];
	my @c = qw<one two>;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'qw with different delimiters');
}

# tr///
{
	my $input = <<'END';
sub foo {
$x =~ tr/a-z/A-Z/;
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	$x =~ tr/a-z/A-Z/;
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'tr/// transliteration');
}

# y///
{
	my $input = <<'END';
sub foo {
$x =~ y/a-z/A-Z/;
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	$x =~ y/a-z/A-Z/;
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'y/// transliteration');
}
