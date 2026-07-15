use strict;
use warnings;
use Test::More;
use Eshu;

# comments inside a block
{
	my $input = <<'END';
if true; then
# this is a comment
echo "body"
# another comment
fi
END

	my $expected = <<'END';
if true; then
	# this is a comment
	echo "body"
	# another comment
fi
END

	is(Eshu->indent_bash($input), $expected, 'comments inside block are indented');
}

# shebang line unchanged at depth 0
{
	my $input = <<'END';
#!/usr/bin/env bash
x=1
if [ "$x" -eq 1 ]; then
echo "yes"
fi
END

	my $expected = <<'END';
#!/usr/bin/env bash
x=1
if [ "$x" -eq 1 ]; then
	echo "yes"
fi
END

	is(Eshu->indent_bash($input), $expected, 'shebang unchanged, rest indented normally');
}

# keyword inside comment not treated as keyword
{
	my $input = <<'END';
# if this were code, fi would close it
echo "not affected"
END

	my $expected = <<'END';
# if this were code, fi would close it
echo "not affected"
END

	is(Eshu->indent_bash($input), $expected, 'keywords inside comments not parsed');
}

# keyword inside double-quoted string not parsed
{
	my $input = <<'END';
if true; then
echo "then do fi done"
fi
END

	my $expected = <<'END';
if true; then
	echo "then do fi done"
fi
END

	is(Eshu->indent_bash($input), $expected, 'keywords inside DQ string not parsed');
}

done_testing;
