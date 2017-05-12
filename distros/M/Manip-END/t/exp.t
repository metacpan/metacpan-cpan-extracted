use strict;

use Manip::END qw( clear_end_array set_end_array );

print "1..1\n";

set_end_array(\&end);

sub end
{
	ok(1, 1, "in my sub");
}

END {
	fail(1, 2, "in end");
}

sub ok
{
	my ($ok, $num, $msg) = @_;

	$msg ||= "";

	print $ok ? "" : "not ";
	print "ok $num - $msg\n"
}
