# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Geo::Coordinates::Convert;

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my ($n, $dlo, $dla);
use vars qw/$lod $lad $lol $lal $lof $laf $err/;

$err= 0;
for ($lad=-89; $lad<90; $lad++) {
	for ($lod=-180; $lod<=181; $lod+=10) {

		set_Mean_Longitude $lod+5;

		($lol, $lal) = geo2lII($lod, $lad);

		($lof, $laf) = lII2geo($lol, $lal);

		if (abs($lad-$laf) > 0.04) {
			$err++;
#			printf "lod=%.2f\tlol=%d\tlof=%.2f\t", $lod, $lol, $lof;
#			printf "lad=%.2f\tlal=%d\tlaf=%.2f\n", $lad, $lal, $laf;
		}
	}
}
ok($err, 0); # If we made it this far, we're ok.
