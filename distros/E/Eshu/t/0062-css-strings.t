use strict;
use warnings;
use Test::More;
use Eshu;

# String with braces in content property
{
	my $input = <<'END';
.icon::before {
content: "{ }";
color: red;
}
END

	my $expected = <<'END';
.icon::before {
	content: "{ }";
	color: red;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'double-quoted string with braces');
}

# Single-quoted string with braces
{
	my $input = <<'END';
.icon::after {
content: '{ block }';
display: inline;
}
END

	my $expected = <<'END';
.icon::after {
	content: '{ block }';
	display: inline;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'single-quoted string with braces');
}

# Escaped quote in string
{
	my $input = <<'END';
.quote::before {
content: "say \"hello\"";
}
END

	my $expected = <<'END';
.quote::before {
	content: "say \"hello\"";
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'escaped quotes in string');
}

done_testing();
