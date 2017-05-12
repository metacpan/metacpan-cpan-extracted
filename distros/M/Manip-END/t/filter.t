use strict;

use Manip::END;

my $test_num = 1;

my $obj = Manip::END->new;

print "1..7\n";

ok(@$obj == 1, "correct size");

$obj->unshift(\&good::end);
$obj->unshift(\&bad::bad_end);

my @pkgs;

$obj->filter_sub(sub { push(@pkgs, shift())});

ok(@pkgs == 3, "num pkgs");
ok($pkgs[0] eq "bad", "pkg 0");
ok($pkgs[1] eq "good", "pkg 1");
ok($pkgs[2] eq "main", "pkg 2");

$obj->remove_isa("bad");

sub ok
{
	my ($ok, $msg) = @_;

	$msg ||= "";

	print $ok ? "" : "not ";
	print "ok $test_num - $msg\n";

	$test_num++;
}

END {
	ok(1, "main end");
}

package good;
sub end
{
	::ok(1, "good end");
}

package bad;

sub bad_end
{
	::ok(0, "bad end");
}

