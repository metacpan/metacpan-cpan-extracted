use strict;
use warnings;
use Test::More;
use Eshu;

# Void elements in HTML mode don't increase depth
{
	my $input = <<'END';
<div>
<br>
<p>text</p>
<hr>
<img src="x">
</div>
END

	my $expected = <<'END';
<div>
	<br>
	<p>text</p>
	<hr>
	<img src="x">
</div>
END

	my $got = Eshu->indent_xml($input, lang => 'html');
	is($got, $expected, 'void elements no depth change in HTML');
}

# Void with attributes
{
	my $input = <<'END';
<form>
<input type="text" name="foo">
<input type="submit" value="Go">
</form>
END

	my $expected = <<'END';
<form>
	<input type="text" name="foo">
	<input type="submit" value="Go">
</form>
END

	my $got = Eshu->indent_xml($input, lang => 'html');
	is($got, $expected, 'void input elements with attributes');
}

# In XML mode, unclosed tags increase depth
{
	my $input = <<'END';
<root>
<br>
<p>text</p>
</root>
END

	my $expected_xml = <<'END';
<root>
	<br>
		<p>text</p>
	</root>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected_xml, 'XML mode: unclosed br increases depth');
}

# meta, link, base, source, embed, track, wbr, col, area, param
{
	my $input = <<'END';
<head>
<meta charset="utf-8">
<link rel="stylesheet" href="s.css">
<base href="/">
</head>
END

	my $expected = <<'END';
<head>
	<meta charset="utf-8">
	<link rel="stylesheet" href="s.css">
	<base href="/">
</head>
END

	my $got = Eshu->indent_xml($input, lang => 'html');
	is($got, $expected, 'meta/link/base void elements');
}

# indent_string with lang html
{
	my $input = <<'END';
<div>
<br>
<p>text</p>
</div>
END

	my $expected = <<'END';
<div>
	<br>
	<p>text</p>
</div>
END

	my $got = Eshu->indent_string($input, lang => 'html');
	is($got, $expected, 'indent_string with lang html');
}

done_testing();
