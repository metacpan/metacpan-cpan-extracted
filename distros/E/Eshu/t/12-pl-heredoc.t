use strict;
use warnings;
use Test::More tests => 6;
use Eshu;

# Basic heredoc pass-through
{
	my $input = <<'END';
sub foo {
my $x = <<EOF;
this should not be reindented
    it keeps its own indentation
EOF
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = <<EOF;
this should not be reindented
    it keeps its own indentation
EOF
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'basic heredoc pass-through');
}

# Heredoc with single quotes
{
	my $input = <<'END';
sub foo {
my $x = <<'EOF';
no $interpolation here
{ braces don't matter }
EOF
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = <<'EOF';
no $interpolation here
{ braces don't matter }
EOF
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'heredoc with single quotes');
}

# Heredoc with double quotes
{
	my $input = <<'END';
sub foo {
my $x = <<"EOF";
hello $world
EOF
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = <<"EOF";
hello $world
EOF
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'heredoc with double quotes');
}

# Indented heredoc <<~
{
	my $input = <<'END';
sub foo {
my $x = <<~EOF;
    hello
    world
    EOF
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = <<~EOF;
    hello
    world
    EOF
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'indented heredoc <<~');
}

# Heredoc with braces in body
{
	my $input = <<'END';
sub foo {
my $html = <<EOF;
<div>
  <p>{ not a hash }</p>
</div>
EOF
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $html = <<EOF;
<div>
  <p>{ not a hash }</p>
</div>
EOF
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'heredoc with braces in body');
}

# Heredoc followed by code on same logical line
{
	my $input = <<'END';
sub foo {
my $x = <<EOF;
body
EOF
if ($x) {
print $x;
}
}
END

	my $expected = <<'END';
sub foo {
	my $x = <<EOF;
body
EOF
	if ($x) {
		print $x;
	}
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'heredoc followed by more code');
}
