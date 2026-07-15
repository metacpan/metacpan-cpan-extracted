use strict;
use warnings;
use Test::More;
use Eshu;

# if/then/fi
{
	my $input = <<'END';
if [ "$x" -eq 1 ]; then
echo "one"
fi
END

	my $expected = <<'END';
if [ "$x" -eq 1 ]; then
	echo "one"
fi
END

	is(Eshu->indent_bash($input), $expected, 'if/then/fi basic');
}

# if/then/else/fi
{
	my $input = <<'END';
if [ "$x" -gt 0 ]; then
echo "positive"
else
echo "non-positive"
fi
END

	my $expected = <<'END';
if [ "$x" -gt 0 ]; then
	echo "positive"
else
	echo "non-positive"
fi
END

	is(Eshu->indent_bash($input), $expected, 'if/then/else/fi');
}

# if/then/elif/else/fi
{
	my $input = <<'END';
if [ "$x" -eq 1 ]; then
echo "one"
elif [ "$x" -eq 2 ]; then
echo "two"
else
echo "other"
fi
END

	my $expected = <<'END';
if [ "$x" -eq 1 ]; then
	echo "one"
elif [ "$x" -eq 2 ]; then
	echo "two"
else
	echo "other"
fi
END

	is(Eshu->indent_bash($input), $expected, 'if/then/elif/else/fi');
}

# for/do/done
{
	my $input = <<'END';
for i in 1 2 3; do
echo "$i"
done
END

	my $expected = <<'END';
for i in 1 2 3; do
	echo "$i"
done
END

	is(Eshu->indent_bash($input), $expected, 'for/do/done');
}

# while/do/done
{
	my $input = <<'END';
while [ "$n" -gt 0 ]; do
echo "$n"
n=$((n - 1))
done
END

	my $expected = <<'END';
while [ "$n" -gt 0 ]; do
	echo "$n"
	n=$((n - 1))
done
END

	is(Eshu->indent_bash($input), $expected, 'while/do/done');
}

# until/do/done
{
	my $input = <<'END';
until [ "$n" -eq 0 ]; do
n=$((n - 1))
done
END

	my $expected = <<'END';
until [ "$n" -eq 0 ]; do
	n=$((n - 1))
done
END

	is(Eshu->indent_bash($input), $expected, 'until/do/done');
}

# nested if inside for
{
	my $input = <<'END';
for f in *.txt; do
if [ -f "$f" ]; then
echo "file: $f"
fi
done
END

	my $expected = <<'END';
for f in *.txt; do
	if [ -f "$f" ]; then
		echo "file: $f"
	fi
done
END

	is(Eshu->indent_bash($input), $expected, 'nested if inside for');
}

# idempotent: already correct
{
	my $input = <<'END';
if [ -n "$VAR" ]; then
	echo "$VAR"
fi
END

	is(Eshu->indent_bash($input), $input, 'already correct is idempotent');
}

# spaces mode
{
	my $input = <<'END';
while true; do
sleep 1
done
END

	my $expected = <<'END';
while true; do
    sleep 1
done
END

	is(Eshu->indent_bash($input, indent_char => ' ', indent_width => 4),
	   $expected, 'spaces mode');
}

done_testing;
