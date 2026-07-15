use strict;
use warnings;
use Test::More;
use Eshu;

# $(...) on a single line — does not open depth
{
	my $input = <<'END';
if [ -n "$(ls)" ]; then
echo "not empty"
fi
END

	my $expected = <<'END';
if [ -n "$(ls)" ]; then
	echo "not empty"
fi
END

	is(Eshu->indent_bash($input), $expected, '$(...) subshell on single line');
}

# $(( )) arithmetic does not affect depth
{
	my $input = <<'END';
while [ $((count--)) -gt 0 ]; do
echo "$count"
done
END

	my $expected = <<'END';
while [ $((count--)) -gt 0 ]; do
	echo "$count"
done
END

	is(Eshu->indent_bash($input), $expected, '$((...)) arithmetic does not open depth');
}

# case pattern ) not confused with subshell )
{
	my $input = <<'END';
case "$(uname)" in
Linux)
echo "linux"
;;
Darwin)
echo "mac"
;;
esac
END

	my $expected = <<'END';
case "$(uname)" in
	Linux)
		echo "linux"
		;;
	Darwin)
		echo "mac"
		;;
esac
END

	is(Eshu->indent_bash($input), $expected, 'case with $(uname) subshell in expression');
}

done_testing;
