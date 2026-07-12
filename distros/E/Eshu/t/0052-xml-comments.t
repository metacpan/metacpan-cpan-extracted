use strict;
use warnings;
use Test::More;
use Eshu;

# Single-line comment
{
	my $input = <<'END';
<root>
<!-- a comment -->
<child>text</child>
</root>
END

	my $expected = <<'END';
<root>
	<!-- a comment -->
	<child>text</child>
</root>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'single-line comment indented correctly');
}

# Multi-line comment
{
	my $input = <<'END';
<root>
<!--
multi line
comment
-->
<child>text</child>
</root>
END

	my $expected = <<'END';
<root>
	<!--
	multi line
	comment
	-->
	<child>text</child>
</root>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'multi-line comment preserved');
}

# Comment doesn't affect depth
{
	my $input = <<'END';
<root>
<a>
<!-- comment between tags -->
<b>text</b>
</a>
</root>
END

	my $expected = <<'END';
<root>
	<a>
		<!-- comment between tags -->
		<b>text</b>
	</a>
</root>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'comment does not affect tag depth');
}

done_testing();
