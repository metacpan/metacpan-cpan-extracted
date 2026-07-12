use strict;
use warnings;
use Test::More;
use Eshu;

# url() with quoted content
{
	my $input = <<'END';
body {
background: url("image.png");
color: black;
}
END

	my $expected = <<'END';
body {
	background: url("image.png");
	color: black;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'url with quoted path');
}

# url() with parentheses in filename
{
	my $input = <<'END';
.bg {
background: url("image (1).png");
}
END

	my $expected = <<'END';
.bg {
	background: url("image (1).png");
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'url with parens in quoted filename');
}

# url() with data URI
{
	my $input = <<'END';
.icon {
background: url(data:image/png;base64,abc123);
display: inline;
}
END

	my $expected = <<'END';
.icon {
	background: url(data:image/png;base64,abc123);
	display: inline;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'url with data URI');
}

# url() unquoted path
{
	my $input = <<'END';
.logo {
background: url(logo.svg) no-repeat;
}
END

	my $expected = <<'END';
.logo {
	background: url(logo.svg) no-repeat;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'url with unquoted path');
}

done_testing();
