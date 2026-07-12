use strict;
use warnings;
use Test::More;
use Eshu;

# Custom property declarations in :root
{
	my $input = <<'END';
:root {
--primary-color: #333;
--secondary-color: #666;
--font-size-base: 16px;
}
END

	my $expected = <<'END';
:root {
	--primary-color: #333;
	--secondary-color: #666;
	--font-size-base: 16px;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'custom property declarations in :root');
}

# var() usage
{
	my $input = <<'END';
.button {
background: var(--primary-color);
color: var(--secondary-color);
font-size: var(--font-size-base);
}
END

	my $expected = <<'END';
.button {
	background: var(--primary-color);
	color: var(--secondary-color);
	font-size: var(--font-size-base);
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'var() usage for custom properties');
}

# var() with fallback value
{
	my $input = <<'END';
.card {
padding: var(--card-padding, 16px);
border-radius: var(--radius, 4px);
box-shadow: var(--shadow, none);
}
END

	my $expected = <<'END';
.card {
	padding: var(--card-padding, 16px);
	border-radius: var(--radius, 4px);
	box-shadow: var(--shadow, none);
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'var() with fallback value');
}

# Custom properties inside @media — nested depth
{
	my $input = <<'END';
@media (prefers-color-scheme: dark) {
:root {
--primary-color: #eee;
--background: #111;
}
}
END

	my $expected = <<'END';
@media (prefers-color-scheme: dark) {
	:root {
		--primary-color: #eee;
		--background: #111;
	}
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'custom properties inside @media');
}

done_testing();
