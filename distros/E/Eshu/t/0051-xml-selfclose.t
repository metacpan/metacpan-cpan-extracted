use strict;
use warnings;
use Test::More;
use Eshu;

# Self-closing tags don't affect depth
{
	my $input = <<'END';
<root>
<item/>
<item/>
</root>
END

	my $expected = <<'END';
<root>
	<item/>
	<item/>
</root>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'self-closing tags no depth change');
}

# Self-closing with space before />
{
	my $input = <<'END';
<root>
<br />
<img src="x" />
</root>
END

	my $expected = <<'END';
<root>
	<br />
	<img src="x" />
</root>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'self-closing with space before />');
}

# Mixed self-closing and nesting
{
	my $input = <<'END';
<div>
<img src="logo.png"/>
<section>
<p>text</p>
<hr/>
</section>
</div>
END

	my $expected = <<'END';
<div>
	<img src="logo.png"/>
	<section>
		<p>text</p>
		<hr/>
	</section>
</div>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'mixed self-closing and nested tags');
}

# XML declaration is a PI — no depth
{
	my $input = <<'END';
<?xml version="1.0"?>
<root>
<child>text</child>
</root>
END

	my $expected = <<'END';
<?xml version="1.0"?>
<root>
	<child>text</child>
</root>
END

	my $got = Eshu->indent_xml($input);
	is($got, $expected, 'XML declaration PI no depth change');
}

done_testing();
