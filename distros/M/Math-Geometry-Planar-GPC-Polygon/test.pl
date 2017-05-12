# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7 + 4 * 3 + 1 + 3 + 2;
use Math::Geometry::Planar::GPC::Polygon qw(new_gpc);
ok(1, "use successful"); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $sub = Math::Geometry::Planar::GPC::Polygon->new();
ok(defined($sub), "constructor working");
my $class = ref($sub);
ok($sub->isa($class), "class is as expected");
my $clp = new_gpc();
ok(defined($clp), "imported constructor working");
ok($clp->isa($class), "imported constructor correct");
ok($sub->can("to_file"), "save to file supported");
ok($sub->can("from_file"), "load from file supported");
my $tdata = "test_data/";
foreach my $action qw(INTERSECT UNION DIFFERENCE) {
	my $c;
	my $res, $sub, $clp;
	ok($c = $sub->from_file($tdata . "subjfile", 1), "read subject ($c)");
	ok($c = $clp->from_file($tdata . "clipfile", 1), "read clip ($c)");
	ok($res = $sub->clip_to($clp, $action), "clip $action working");
	ok(do {print $res->as_string(), "\n"}, "stringification");
}

#exit;

my @bound = (
  [1.29219233231504,1.2212767893659],
  [839.971080497408,-97.5227766759753],
  [839.971080497408,59.6616354212312],
  [654.494019559105,132.208286121488],
  [839.971080497408,164.451243111594],
  [839.971080497408,325.666023568823],
  [916.581172169519,517.108576607062],
  [-99.5105582362971,478.820067028089],
  [1.29219233231504,241.028263295198],
);

my @holes = (
 [
   [304.139187477841,404.758607435417],
   [394.215618931913,262.776318262066],
   [184.614691212324,229.877983705177],
   [167.292300320669,397.832642383731],
 ],
 [
   [458.308465526667,127.7199941404],
   [505.078921229765,127.7199941404],
   [505.078921229765,51.5343763263377],
   [458.308465526667,51.5343763263377],
 ],
 [
   [260.833208770543,157.155347294201],
   [272.958882690334,39.4139369245086],
   [212.330516047706,34.2194625743655],
   [188.079168208125,148.497889295459],
 ],
);

if(1) {
	my $sub = Math::Geometry::Planar::GPC::Polygon->new();
	print "add polygon\n";
	$sub->add_polygon(\@bound, 0);
	ok(1, "add polygon");
	foreach my $hole (@holes) {
		$sub->add_polygon($hole, 1);
		ok(1, "add hole");
	}
	$clp->add_polygon(\@rec, 0);

	my $res;
	my $action = "INTERSECT";
	ok($res = $sub->clip_to($clp, $action), "clip $action working");
	ok(do {print $res->as_string(), "\n"}, "stringification");
}
