use strict;
use warnings;
use Test::More;
use Eshu;

# basic case/esac
{
	my $input = <<'END';
case "$opt" in
-h)
echo "help"
;;
-v)
echo "verbose"
;;
esac
END

	my $expected = <<'END';
case "$opt" in
	-h)
		echo "help"
		;;
	-v)
		echo "verbose"
		;;
esac
END

	is(Eshu->indent_bash($input), $expected, 'case/esac basic');
}

# case with * wildcard pattern
{
	my $input = <<'END';
case "$1" in
start)
do_start
;;
stop)
do_stop
;;
*)
echo "unknown"
;;
esac
END

	my $expected = <<'END';
case "$1" in
	start)
		do_start
		;;
	stop)
		do_stop
		;;
	*)
		echo "unknown"
		;;
esac
END

	is(Eshu->indent_bash($input), $expected, 'case with wildcard pattern');
}

# case inside if
{
	my $input = <<'END';
if [ -n "$1" ]; then
case "$1" in
foo)
echo "foo"
;;
esac
fi
END

	my $expected = <<'END';
if [ -n "$1" ]; then
	case "$1" in
		foo)
			echo "foo"
			;;
	esac
fi
END

	is(Eshu->indent_bash($input), $expected, 'case nested inside if');
}

done_testing;
