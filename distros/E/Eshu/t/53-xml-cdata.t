use strict;
use warnings;
use Test::More;
use Eshu;

# Single-line CDATA
{
	my $input = <<'END';
<root>
<data><![CDATA[some raw data]]></data>
</root>
END

	my $expected = <<'END';
<root>
	<data><![CDATA[some raw data]]></data>
</root>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'single-line CDATA section');
}

# Multi-line CDATA
{
	my $input = <<'END';
<root>
<data><![CDATA[
line one
line two
]]></data>
</root>
END

	my $expected = <<'END';
<root>
	<data><![CDATA[
		line one
		line two
		]]></data>
</root>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'multi-line CDATA section');
}

# DOCTYPE no depth change
{
	my $input = <<'END';
<!DOCTYPE html>
<html>
<body>
<p>text</p>
</body>
</html>
END

	my $expected = <<'END';
<!DOCTYPE html>
<html>
	<body>
		<p>text</p>
	</body>
</html>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'DOCTYPE does not affect depth');
}

done_testing();
