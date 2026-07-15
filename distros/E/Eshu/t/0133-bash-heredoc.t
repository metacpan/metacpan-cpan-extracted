use strict;
use warnings;
use Test::More;
use Eshu;

# basic heredoc body is emitted verbatim
{
	my $input = <<'END';
cat <<EOF
line one
  indented line
line three
EOF
END

	my $expected = <<'END';
cat <<EOF
line one
  indented line
line three
EOF
END

	is(Eshu->indent_bash($input), $expected, 'heredoc body emitted verbatim');
}

# heredoc inside if block — body still verbatim, surrounding code indented
{
	my $input = <<'END';
if true; then
cat <<MSG
hello world
MSG
echo "done"
fi
END

	my $expected = <<'END';
if true; then
	cat <<MSG
hello world
MSG
	echo "done"
fi
END

	is(Eshu->indent_bash($input), $expected, 'heredoc inside if block');
}

# <<- (strip-indent) heredoc
{
	my $input = <<'END';
if true; then
cat <<-EOF
	stripped
	lines
EOF
fi
END

	my $expected = <<'END';
if true; then
	cat <<-EOF
	stripped
	lines
EOF
fi
END

	is(Eshu->indent_bash($input), $expected, '<<- heredoc body verbatim');
}

done_testing;
