use strict;

use Manip::END;

my $obj = Manip::END->new;

print "1..3\n";

ok(@$obj == 1, 1, "correct size");

$obj->unshift(\&end);

sub end
{
	ok(1, 2, "in my sub");
}

END {
	ok(1, 3, "in end");
}

sub ok
{
	my ($ok, $num, $msg) = @_;

	$msg ||= "";

	print $ok ? "" : "not ";
	print "ok $num - $msg\n"
}
