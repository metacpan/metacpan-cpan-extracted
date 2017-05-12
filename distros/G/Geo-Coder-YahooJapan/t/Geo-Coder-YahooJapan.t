# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Geo-Coder-YahooJapan.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('Geo::Coder::YahooJapan') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Geo::Coder::YahooJapan;
use Location::GeoTool;

my $precision = 0.0002;

{
	my $r = Geo::Coder::YahooJapan::lookup("神奈川県川崎市中原区井田2-21-6");
	ok ( defined $r);

	my $lat = 35.5608;
	my $lng = 139.6427;

	ok ( ( abs($r->{latitude} - $lat) < $precision / 2 ) and
			( abs($r->{longitude} - $lng) < $precision ) );
}

# tokyo
{
	my $r = Geo::Coder::YahooJapan::lookup("神奈川県川崎市中原区井田2-21-6", {datum => 'tokyo' });
	ok ( defined $r);

	my $lat = 35.5575;
	my $lng = 139.6460;

	ok ( ( abs($r->{latitude} - $lat) < $precision / 2 ) and
			( abs($r->{longitude} - $lng) < $precision ) );
}

# multiple matches.
{
	my $r = Geo::Coder::YahooJapan::lookup("東京都渋谷区東");
	ok ( defined $r);

	my $lat = 35.6533;
	my $lng = 139.7099;

	ok ( ( abs($r->{latitude} - $lat) < $precision / 2 ) and
			( abs($r->{longitude} - $lng) < $precision ) );

	ok( $r->{hits} > 1 );
	ok( $r->{latitude} == ${$r->{items}}[0]->{latitude} and 
			$r->{longitude} == ${$r->{items}}[0]->{longitude} );
}

