use strict;
use Test;
BEGIN { plan tests => 1 }
use Math::BigSimple qw(is_simple);
$Math::BigSimple::_DEFAULT_CHECKS = 10; # (*)

#
# TEST 3 - we expect to find following ten numbers
# between 100 and 150:
#  101, 103, 107, 109, 113, 127, 137, 139, 149.
#
# The test in the previous version failed in
# two cases of four because too small numbers
# were used (3 and 7 not always recognized).
# To avoid this error now numbers more then 100
# used in test and - see (*) - number of
# checks was increased from 4 to 10.
#

my $loc = 0;
for(my $i = 100; $i <= 150; $i ++)
{
	if(is_simple($i) == 1)
	{
		$loc ++;

		# To debug, uncomment this:
		# print "# $i\n";
	}
}

if($loc == 10)
{
	ok(1);
}
else
{
	ok(0);
}
