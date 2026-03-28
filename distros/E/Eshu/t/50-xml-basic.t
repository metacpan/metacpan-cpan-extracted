use strict;
use warnings;
use Test::More;
use Eshu;

# Simple nested tags
{
	my $input = <<'END';
<root>
<child>
<grandchild>text</grandchild>
</child>
</root>
END

	my $expected = <<'END';
<root>
	<child>
		<grandchild>text</grandchild>
	</child>
</root>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'simple nested XML tags');
}

# Already correct — idempotent
{
	my $input = <<'END';
<root>
	<child>text</child>
</root>
END

	my $got = Eshu->indent_xml($input);
	is($got, $input, 'already correct indentation is idempotent');
}

# Multiple siblings
{
	my $input = <<'END';
<list>
<item>one</item>
<item>two</item>
<item>three</item>
</list>
END

	my $expected = <<'END';
<list>
	<item>one</item>
	<item>two</item>
	<item>three</item>
</list>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'multiple sibling elements');
}

# Deeply nested
{
	my $input = <<'END';
<a>
<b>
<c>
<d>deep</d>
</c>
</b>
</a>
END

	my $expected = <<'END';
<a>
	<b>
		<c>
			<d>deep</d>
		</c>
	</b>
</a>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'deeply nested tags');
}

# With spaces option
{
	my $input = <<'END';
<root>
<child>text</child>
</root>
END

	my $expected = <<'END';
<root>
    <child>text</child>
</root>
END

	my $got = Eshu->indent_xml($input, indent_char => ' ', indent_width => 4);
	is($got, $expected, 'spaces indentation');
}

# Empty root
{
	my $input = <<'END';
<root>
</root>
END

	my $expected = <<'END';
<root>
</root>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'empty root element');
}

# Inline tags on same line — no change
{
	my $input = <<'END';
<p>Hello <em>world</em> foo</p>
END

	my $got = Eshu->indent_xml($input);
	is($got, $input, 'inline tags on same line cancel out');
}

# indent_string with lang => xml
{
	my $input = <<'END';
<root>
<child/>
</root>
END

	my $expected = <<'END';
<root>
	<child/>
</root>
END

	my $got = Eshu->indent_string($input, lang => 'xml');
	is($got, $expected, 'indent_string with lang xml');
}

done_testing();
