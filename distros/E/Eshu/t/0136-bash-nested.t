use strict;
use warnings;
use Test::More;
use Eshu;

# deeply nested: function > for > if
{
	my $input = <<'END';
process_files() {
for f in "$@"; do
if [ -f "$f" ]; then
echo "processing $f"
else
echo "skipping $f"
fi
done
}
END

	my $expected = <<'END';
process_files() {
	for f in "$@"; do
		if [ -f "$f" ]; then
			echo "processing $f"
		else
			echo "skipping $f"
		fi
	done
}
END

	is(Eshu->indent_bash($input), $expected, 'function > for > if nesting');
}

# while > case > if
{
	my $input = <<'END';
while read -r line; do
case "$line" in
\#*)
continue
;;
*)
if [ -n "$line" ]; then
process "$line"
fi
;;
esac
done
END

	my $expected = <<'END';
while read -r line; do
	case "$line" in
		\#*)
			continue
			;;
		*)
			if [ -n "$line" ]; then
				process "$line"
			fi
			;;
	esac
done
END

	is(Eshu->indent_bash($input), $expected, 'while > case > if nesting');
}

done_testing;
