use strict;
use warnings;
use Test::More tests => 6;
use Eshu;

# Regex match with braces inside
{
	my $input = <<'END';
sub foo {
if ($x =~ /\{pattern\}/) {
print "matched\n";
}
}
END

	my $expected = <<'END';
sub foo {
	if ($x =~ /\{pattern\}/) {
		print "matched\n";
	}
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'regex with braces via =~');
}

# Regex at start of condition
{
	my $input = <<'END';
sub foo {
if (/pattern/) {
print "yes\n";
}
}
END

	my $expected = <<'END';
sub foo {
	if (/pattern/) {
		print "yes\n";
	}
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'regex at start of condition');
}

# Division should not be confused with regex
{
	my $input = <<'END';
sub foo {
my $x = $y / $z;
my $w = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = $y / $z;
	my $w = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'division not confused with regex');
}

# m// regex
{
	my $input = <<'END';
sub foo {
if ($x =~ m{pattern}) {
print "yes\n";
}
}
END

	my $expected = <<'END';
sub foo {
	if ($x =~ m{pattern}) {
		print "yes\n";
	}
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'm{} regex');
}

# s/// substitution
{
	my $input = <<'END';
sub foo {
$x =~ s/foo/bar/g;
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	$x =~ s/foo/bar/g;
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 's/// substitution');
}

# s{}{} substitution with braces
{
	my $input = <<'END';
sub foo {
$x =~ s{foo}{bar}g;
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	$x =~ s{foo}{bar}g;
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 's{}{} substitution with paired delimiters');
}
