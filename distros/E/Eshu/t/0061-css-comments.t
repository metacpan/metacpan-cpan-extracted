use strict;
use warnings;
use Test::More;
use Eshu;

# Single-line comment
{
	my $input = <<'END';
/* reset */
body {
color: black;
}
END

	my $expected = <<'END';
/* reset */
body {
	color: black;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'single-line comment before rule');
}

# Comment inside rule
{
	my $input = <<'END';
body {
/* text color */
color: red;
/* font */
font-size: 14px;
}
END

	my $expected = <<'END';
body {
	/* text color */
	color: red;
	/* font */
	font-size: 14px;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'comments inside rule');
}

# Multi-line comment
{
	my $input = <<'END';
/*
 * Reset styles
 * for all elements
 */
body {
margin: 0;
}
END

	my $expected = <<'END';
/*
* Reset styles
* for all elements
*/
body {
	margin: 0;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'multi-line comment');
}

# Comment containing braces
{
	my $input = <<'END';
/* .foo { color: red; } */
body {
color: blue;
}
END

	my $expected = <<'END';
/* .foo { color: red; } */
body {
	color: blue;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'comment containing braces ignored');
}

done_testing();
