use strict;
use warnings;
use Test::More tests => 8;
use Eshu;

# Line comment
{
	my $input = <<'END';
sub foo {
# a comment
my $x = 1;
}
END

	my $expected = <<'END';
sub foo {
	# a comment
	my $x = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'line comment');
}

# Comment with brace
{
	my $input = <<'END';
sub foo {
# { this brace is in a comment
my $x = 1;
}
END

	my $expected = <<'END';
sub foo {
	# { this brace is in a comment
	my $x = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'comment with brace');
}

# Inline comment
{
	my $input = <<'END';
sub foo {
my $x = 1; # { inline comment with brace
my $y = 2;
}
END

	my $expected = <<'END';
sub foo {
	my $x = 1; # { inline comment with brace
	my $y = 2;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'inline comment with brace');
}

# Hash # in string is not a comment
{
	my $input = <<'END';
sub foo {
my $x = "not # a comment { }";
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = "not # a comment { }";
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'hash in string is not a comment');
}

# Comment-only file
{
	my $input = <<'END';
# This is just comments
# No code at all
END

	my $expected = <<'END';
# This is just comments
# No code at all
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'comment-only at top level');
}

# Shebang line preserved at column 0
{
	my $input = <<'END';
#!/usr/bin/perl
use strict;
use warnings;

sub hello {
print "Hello\n";
}
END

	my $expected = <<'END';
#!/usr/bin/perl
use strict;
use warnings;

sub hello {
	print "Hello\n";
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'shebang line preserved at column 0');
}

# Dense comment block between subs
{
	my $input = <<'END';
sub foo {
return 1;
}

##############################################
# Section heading
##############################################

sub bar {
return 2;
}
END

	my $expected = <<'END';
sub foo {
	return 1;
}

##############################################
# Section heading
##############################################

sub bar {
	return 2;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'dense comment block between subs');
}

# Closing brace in comment does not close block
{
	my $input = <<'END';
sub outer {
my $x = 1;
# } this closing brace is a comment
my $y = 2;
}
END

	my $expected = <<'END';
sub outer {
	my $x = 1;
	# } this closing brace is a comment
	my $y = 2;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'closing brace in comment does not affect depth');
}
