use strict;
use warnings;
use Test::More;
use Eshu;

# Modern CSS nesting
{
	my $input = <<'END';
.parent {
color: blue;
.child {
color: red;
}
}
END

	my $expected = <<'END';
.parent {
	color: blue;
	.child {
		color: red;
	}
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'modern CSS nesting');
}

# Deeply nested
{
	my $input = <<'END';
.a {
.b {
.c {
color: red;
}
}
}
END

	my $expected = <<'END';
.a {
	.b {
		.c {
			color: red;
		}
	}
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'deeply nested CSS');
}

# Nested with & selector
{
	my $input = <<'END';
.btn {
color: white;
&:hover {
color: yellow;
}
&.active {
font-weight: bold;
}
}
END

	my $expected = <<'END';
.btn {
	color: white;
	&:hover {
		color: yellow;
	}
	&.active {
		font-weight: bold;
	}
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'nested with & selector');
}

# Nested media inside rule
{
	my $input = <<'END';
.card {
padding: 20px;
@media (max-width: 600px) {
padding: 10px;
}
}
END

	my $expected = <<'END';
.card {
	padding: 20px;
	@media (max-width: 600px) {
		padding: 10px;
	}
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'nested @media inside rule');
}

done_testing();
