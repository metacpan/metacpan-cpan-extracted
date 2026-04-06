use strict;
use warnings;
use Test::More;
use Eshu;

# @keyframes with from/to
{
	my $input = <<'END';
@keyframes slide-in {
from {
transform: translateX(-100%);
}
to {
transform: translateX(0);
}
}
END

	my $expected = <<'END';
@keyframes slide-in {
	from {
		transform: translateX(-100%);
	}
	to {
		transform: translateX(0);
	}
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, '@keyframes with from/to');
}

# @keyframes with percentage selectors
{
	my $input = <<'END';
@keyframes bounce {
0% {
transform: translateY(0);
}
50% {
transform: translateY(-20px);
}
100% {
transform: translateY(0);
}
}
END

	my $expected = <<'END';
@keyframes bounce {
	0% {
		transform: translateY(0);
	}
	50% {
		transform: translateY(-20px);
	}
	100% {
		transform: translateY(0);
	}
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, '@keyframes with percentage selectors');
}

# Pseudo-element selectors
{
	my $input = <<'END';
.button::before {
content: '';
position: absolute;
left: 0;
}
.button::after {
content: '';
width: 100%;
height: 2px;
}
END

	my $expected = <<'END';
.button::before {
	content: '';
	position: absolute;
	left: 0;
}
.button::after {
	content: '';
	width: 100%;
	height: 2px;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'pseudo-element ::before and ::after');
}

# Multiple comma-separated selectors
{
	my $input = <<'END';
h1,
h2,
h3 {
margin: 0;
padding: 0;
font-weight: bold;
}
END

	my $expected = <<'END';
h1,
h2,
h3 {
	margin: 0;
	padding: 0;
	font-weight: bold;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'multiple comma-separated selectors');
}

# @layer rule
{
	my $input = <<'END';
@layer base {
body {
margin: 0;
padding: 0;
}
a {
color: inherit;
text-decoration: none;
}
}
END

	my $expected = <<'END';
@layer base {
	body {
		margin: 0;
		padding: 0;
	}
	a {
		color: inherit;
		text-decoration: none;
	}
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, '@layer with nested rules');
}

# Pseudo-class :is() with multiple selectors
{
	my $input = <<'END';
:is(h1, h2, h3) {
line-height: 1.2;
}
:is(ul, ol) > li {
margin-bottom: 0.5em;
}
END

	my $expected = <<'END';
:is(h1, h2, h3) {
	line-height: 1.2;
}
:is(ul, ol) > li {
	margin-bottom: 0.5em;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, ':is() pseudo-class selector');
}

# @keyframes used inside @media
{
	my $input = <<'END';
@media (prefers-reduced-motion: no-preference) {
@keyframes spin {
from {
transform: rotate(0deg);
}
to {
transform: rotate(360deg);
}
}
.spinner {
animation: spin 1s linear infinite;
}
}
END

	my $expected = <<'END';
@media (prefers-reduced-motion: no-preference) {
	@keyframes spin {
		from {
			transform: rotate(0deg);
		}
		to {
			transform: rotate(360deg);
		}
	}
	.spinner {
		animation: spin 1s linear infinite;
	}
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, '@keyframes nested inside @media');
}

done_testing();
