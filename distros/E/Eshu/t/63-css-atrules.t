use strict;
use warnings;
use Test::More;
use Eshu;

# @media query
{
	my $input = <<'END';
@media (max-width: 768px) {
.container {
width: 100%;
}
}
END

	my $expected = <<'END';
@media (max-width: 768px) {
	.container {
		width: 100%;
	}
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, '@media query nesting');
}

# @keyframes
{
	my $input = <<'END';
@keyframes fadeIn {
0% {
opacity: 0;
}
100% {
opacity: 1;
}
}
END

	my $expected = <<'END';
@keyframes fadeIn {
	0% {
		opacity: 0;
	}
	100% {
		opacity: 1;
	}
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, '@keyframes nesting');
}

# @supports
{
	my $input = <<'END';
@supports (display: grid) {
.grid {
display: grid;
}
}
END

	my $expected = <<'END';
@supports (display: grid) {
	.grid {
		display: grid;
	}
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, '@supports nesting');
}

# @layer
{
	my $input = <<'END';
@layer base {
body {
margin: 0;
}
}
END

	my $expected = <<'END';
@layer base {
	body {
		margin: 0;
	}
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, '@layer nesting');
}

# @supports with compound and condition
{
	my $input = <<'END';
@supports (display: grid) and (gap: 10px) {
.grid {
display: grid;
gap: 10px;
}
}
END

	my $expected = <<'END';
@supports (display: grid) and (gap: 10px) {
	.grid {
		display: grid;
		gap: 10px;
	}
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, '@supports with compound and condition');
}

# @page rule
{
	my $input = <<'END';
@page {
margin: 1in;
orphans: 3;
}
@page :first {
margin-top: 2in;
}
END

	my $expected = <<'END';
@page {
	margin: 1in;
	orphans: 3;
}
@page :first {
	margin-top: 2in;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, '@page rule');
}

done_testing();
