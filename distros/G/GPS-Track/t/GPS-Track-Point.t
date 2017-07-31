use Test::More;
use Test::Exception;
use Test::Deep;
use strict;
use warnings;
use Geo::Distance;
use DateTime;

BEGIN { use_ok("GPS::Track::Point"); }


subtest(simplePoint => \&simplePoint);
subtest(pointConstructor => \&pointConstructor);
subtest(pointSettersGetters => \&pointSettersGetters);
subtest(pointsEqual => \&pointsEqual);
subtest(pointDistances => \&pointDistances);
subtest(timeHandling => \&timeHandling);
subtest(toString => \&testToString);
subtest(toHash => \&testToHash);

sub simplePoint {
	my $point = GPS::Track::Point->new();

	# Attributes
	ok($point->can("lon"), "point can lon");
	ok($point->can("lat"), "point can lat");
	ok($point->can("ele"), "point can ele");
	ok($point->can("bpm"), "point can bpm");
	ok($point->can("cad"), "point can cad");
	ok($point->can("spd"), "point can spd");
	ok($point->can("time"), "point can time");
	# Methods
	ok($point->can("equals"), "point can equals");

	is($point->lon, undef, "lon is undef");
	is($point->lat, undef, "lat is undef");
	is($point->ele, undef, "ele is undef");
	is($point->bpm, undef, "bpm is undef");
	is($point->cad, undef, "cad is undef");
	is($point->spd, undef, "spd is undef");
	is($point->time, undef, "time is undef");
}

sub pointConstructor {
	my @arrayInit = (lon => 12, lat => 17, ele => 8848, bpm => 60, cad => 90, spd => 10);
	my $hashRefInit = {@arrayInit};

	my $pointIsGood = sub {
		my $point = shift;
		is($point->lon, 12);
		is($point->lat, 17);
		is($point->ele, 8848);
		is($point->bpm, 60);
		is($point->cad, 90);
		is($point->spd, 10);
	};
	
	note("point constructor with hashref");
	my $point = GPS::Track::Point->new($hashRefInit);
	$pointIsGood->($point);

	note("point constructor with array");
	$point = GPS::Track::Point->new(@arrayInit);
	$pointIsGood->($point);
}

sub pointSettersGetters {
	my $point = GPS::Track::Point->new();

	$point->lon(10);
	is($point->lon, 10);

	$point->lat(20);
	is($point->lat(), 20);

	$point->ele(8848);
	is($point->ele, 8848);

	$point->bpm(120);
	is($point->bpm, 120);

	$point->cad(75);
	is($point->cad, 75);
}

sub pointsEqual {
	my $initA = { lon => 12, lat => 13, ele => 8848, cad => 0, bpm => 0, spd => 10 };
	my $initB = { lon => -12, lat => 9, ele => 0, cad => 70, bpm => 120 };
	my $pointA = GPS::Track::Point->new($initA);
	my $pointB = GPS::Track::Point->new($initB);

	is($pointA->equals($pointB), 0, "points aren't equal");
	ok($pointA != $pointB, "operator!= works too");

	$pointB = GPS::Track::Point->new($initA);
	is($pointA->equals($pointB), 1, "points are equal");
	ok($pointA == $pointB, "operator== works too");

	$pointB->lon(0);
	is($pointA->equals($pointB), 0, "points aren't equal");

	# special handling for undef values
	$pointB->lon(undef);
	is($pointA->equals($pointB), 0, "points aren't equal");

	$pointA->lon(undef);
	is($pointA->equals($pointB), 1, "points aren't equal");


	# always equal
	is($pointA->equals($pointA), 1, "points equal");

	throws_ok { $pointA->equals("something"); } qr/not a GPS::Track::Point/;

}

sub pointDistances {
	my $expected = Geo::Distance->new->distance("meter", 9, 48, 8, 47);

	my $pointA = GPS::Track::Point->new( lon => 9, lat => 48 );
	my $pointB = GPS::Track::Point->new( lon => 8, lat => 47 );

	is($pointA->distanceTo($pointB), $expected);
	is($pointA->distanceTo( { lat => $pointB->lat, lon => $pointB->lon } ), $expected);

	my $badPoint = GPS::Track::Point->new();
	throws_ok { $badPoint->distanceTo($pointA); } qr/self.*missing.*lon/;

	$badPoint->lon(12);
	throws_ok { $badPoint->distanceTo($pointA); } qr/self.*missing.*lat/;

	$badPoint->lon(undef);

	throws_ok { $pointA->distanceTo($badPoint); } qr/other.*missing.*lon/;
	$badPoint->lon(12);
	throws_ok { $pointA->distanceTo($badPoint); } qr/other.*missing.*lat/;

	throws_ok { $pointA->distanceTo({ }); } qr/other.*missing.*lon/;
	throws_ok { $pointA->distanceTo({ lon => 12 }); } qr/other.*missing.*lat/;

	throws_ok { $pointA->distanceTo("Hello"); } qr/is not a hash/i;
	throws_ok { $pointA->distanceTo(DateTime->now()); } qr/is not a GPS::Track::Point/i;
}

sub timeHandling {
	my $point = GPS::Track::Point->new();

	my $dt = DateTime->now;

	$point->time($dt);
	is($point->time->iso8601, $dt->iso8601);

	throws_ok { $point->time("something"); } qr/not a datetime/i;

	$point->time(undef);
	is($point->time(), undef, "can still be undef");
}

sub testToString {
	my $point = GPS::Track::Point->new(lon => 12, lat => 13, ele => 8848);
	ok(length($point->toString()) > 0, "at least there is something");
}

sub testToHash {
	my $point = GPS::Track::Point->new();
	cmp_deeply($point->toHash(), {}, "Empty hash");

	my $expected = {
		lon => 12,
		lat => 13,
		ele => 1234
	};

	$point->lon(12);
	$point->lat(13);
	$point->ele(1234);

	cmp_deeply($point->toHash(), $expected, "lon, lat and ele work");

	$expected->{cad} = 90;
	$expected->{bpm} = 120;
	$expected->{spd} = 3;

	$point->cad(90);
	$point->bpm(120);
	$point->spd(3);

	cmp_deeply($point->toHash(), $expected, "added cad, bpm and spd without trouble");

	$point->spd(undef);
	delete($expected->{spd});

	cmp_deeply($point->toHash(), $expected, "spd vanished as expected");
	
}
done_testing;
