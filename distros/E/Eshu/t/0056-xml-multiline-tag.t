use strict;
use warnings;
use Test::More;
use Eshu;

# Tag with attributes on multiple lines
{
	my $input = <<'END';
<div
class="foo"
id="bar">
<p>text</p>
</div>
END

	my $expected = <<'END';
<div
	class="foo"
	id="bar">
	<p>text</p>
</div>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'multiline tag attributes at depth+1');
}

# Self-closing multiline tag
{
	my $input = <<'END';
<root>
<img
src="logo.png"
alt="Logo"/>
<p>text</p>
</root>
END

	my $expected = <<'END';
<root>
	<img
		src="logo.png"
		alt="Logo"/>
	<p>text</p>
</root>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'self-closing multiline tag');
}

# Deeply nested multiline tag
{
	my $input = <<'END';
<html>
<body>
<div
class="container"
data-value="123">
<span>text</span>
</div>
</body>
</html>
END

	my $expected = <<'END';
<html>
	<body>
		<div
			class="container"
			data-value="123">
			<span>text</span>
		</div>
	</body>
</html>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'deeply nested multiline tag');
}

done_testing();
