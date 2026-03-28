use strict;
use warnings;
use Test::More tests => 9;
use Eshu;

# Simple sub
{
	my $input = <<'END';
sub foo {
my $x = 1;
my $y = 2;
}
END

	my $expected = <<'END';
sub foo {
	my $x = 1;
	my $y = 2;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'simple sub');
}

# Nested if/else
{
	my $input = <<'END';
sub foo {
if ($x) {
print "yes\n";
} else {
print "no\n";
}
}
END

	my $expected = <<'END';
sub foo {
	if ($x) {
		print "yes\n";
	} else {
		print "no\n";
	}
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'nested if/else');
}

# For loop
{
	my $input = <<'END';
for my $i (0 .. 10) {
if ($i > 5) {
print "$i\n";
}
}
END

	my $expected = <<'END';
for my $i (0 .. 10) {
	if ($i > 5) {
		print "$i\n";
	}
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'for loop with nested if');
}

# While loop
{
	my $input = <<'END';
while (my $line = <STDIN>) {
chomp $line;
push @lines, $line;
}
END

	my $expected = <<'END';
while (my $line = <STDIN>) {
	chomp $line;
	push @lines, $line;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'while loop');
}

# Idempotent
{
	my $input = <<'END';
sub foo {
	my $x = 1;
	if ($x) {
		return $x;
	}
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $input, 'already indented — idempotent');
}

# Empty lines preserved
{
	my $input = <<'END';
sub foo {
my $x = 1;

my $y = 2;
}
END

	my $expected = <<'END';
sub foo {
	my $x = 1;

	my $y = 2;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'empty lines preserved');
}

# Multiple subs
{
	my $input = <<'END';
sub foo {
return 1;
}

sub bar {
return 2;
}
END

	my $expected = <<'END';
sub foo {
	return 1;
}

sub bar {
	return 2;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'multiple subs');
}

# Spaces mode
{
	my $input = <<'END';
sub foo {
my $x = 1;
}
END

	my $expected = <<'END';
sub foo {
    my $x = 1;
}
END

	my $got = Eshu->indent_pl($input, indent_char => ' ', indent_width => 4);
	is($got, $expected, 'spaces mode');
}

# Hashref and arrayref nesting
{
	my $input = <<'END';
my $data = {
foo => [
1,
2,
3,
],
bar => {
baz => 1,
},
};
END

	my $expected = <<'END';
my $data = {
	foo => [
		1,
		2,
		3,
	],
	bar => {
		baz => 1,
	},
};
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'hashref and arrayref nesting');
}
