use strict;
use warnings;
use Test::More;
use Eshu;

# Real-world CSS snippet
{
	my $input = <<'END';
:root {
--primary: #333;
--bg: #fff;
}
body {
margin: 0;
padding: 0;
font-family: sans-serif;
color: var(--primary);
background: var(--bg);
}
.container {
max-width: 1200px;
margin: 0 auto;
padding: 0 20px;
}
END

	my $expected = <<'END';
:root {
	--primary: #333;
	--bg: #fff;
}
body {
	margin: 0;
	padding: 0;
	font-family: sans-serif;
	color: var(--primary);
	background: var(--bg);
}
.container {
	max-width: 1200px;
	margin: 0 auto;
	padding: 0 20px;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'real-world CSS snippet');
}

# detect_lang for CSS extensions
{
	is(Eshu->detect_lang('style.css'),   'css', 'detect css');
	is(Eshu->detect_lang('app.scss'),    'css', 'detect scss');
	is(Eshu->detect_lang('theme.less'),  'css', 'detect less');
	is(Eshu->detect_lang('FILE.CSS'),    'css', 'detect CSS uppercase');
}

# Complex: media + nested + comments + strings
{
	my $input = <<'END';
/* Main layout */
@media screen and (min-width: 768px) {
.nav {
display: flex;
/* links */
a {
color: blue;
&:hover {
color: red;
}
}
}
.footer {
text-align: center;
}
}
END

	my $expected = <<'END';
/* Main layout */
@media screen and (min-width: 768px) {
	.nav {
		display: flex;
		/* links */
		a {
			color: blue;
			&:hover {
				color: red;
			}
		}
	}
	.footer {
		text-align: center;
	}
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'complex nested media + comments');
}

# Brace on same line as close — e.g. }  followed by rule
{
	my $input = <<'END';
a { color: red; }
b { color: blue; }
END

	my $got = Eshu->indent_css($input);
	is($got, $input, 'single-line rules stay unchanged');
}

done_testing();
