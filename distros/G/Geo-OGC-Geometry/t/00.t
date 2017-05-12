use Test::More qw(no_plan);

BEGIN { 
    use_ok( 'Geo::OGC::Geometry' );
}

my $g = Geo::OGC::Geometry->new(Text => 'geometrycollection empty');
ok($g->AsText eq 'GEOMETRYCOLLECTION EMPTY', "empty");

my $p = new Geo::OGC::Polygon;
my $r = new Geo::OGC::LinearRing;
$r->AddPoint(Geo::OGC::Point->new(0, 0));
$r->AddPoint(Geo::OGC::Point->new(1, 0));
$r->AddPoint(Geo::OGC::Point->new(1, 1));
$r->AddPoint(Geo::OGC::Point->new(0, 1));
$r->Close;
$p->ExteriorRing($r);
#$p->AddInteriorRing(1);


ok($p->IsPointIn(Geo::OGC::Point->new(0.5, 0.5)), "point in polygon a");
ok(!$p->IsPointIn(Geo::OGC::Point->new(-0.5, 0.5)), "point in polygon b");
ok(!$p->IsPointIn(Geo::OGC::Point->new(-0.5, -0.5)), "point in polygon c");
ok(!$p->IsPointIn(Geo::OGC::Point->new(0.5, -0.5)), "point in polygon d");
ok(!$p->IsPointIn(Geo::OGC::Point->new(1.5, -0.5)), "point in polygon e");
ok(!$p->IsPointIn(Geo::OGC::Point->new(1.5, 0.5)), "point in polygon f");
ok(!$p->IsPointIn(Geo::OGC::Point->new(1.5, 1.5)), "point in polygon g");
ok(!$p->IsPointIn(Geo::OGC::Point->new(0.5, 1.5)), "point in polygon h");
ok(!$p->IsPointIn(Geo::OGC::Point->new(-0.5, 1.5)), "point in polygon i");

ok(Geo::OGC::Point->new(0.5, 0)->DistanceToLineStringSqr($r) < 0.0001,"distance of point a");
ok(Geo::OGC::Point->new(1, 0.5)->DistanceToLineStringSqr($r) < 0.0001,"distance of point b");
ok(Geo::OGC::Point->new(0.5, 1)->DistanceToLineStringSqr($r) < 0.0001,"distance of point c");
ok(Geo::OGC::Point->new(0, 0.5)->DistanceToLineStringSqr($r) < 0.0001,"distance of point d");

ok($r->Area == 1, "area");
ok(is_deeply($r->Centroid, Geo::OGC::Point->new(0.5, 0.5)), "centroid");

my $P = $p->MakeCollection;

#print STDERR $p->AsText,"\n";
my $q = Geo::OGC::Geometry->new(Text => $p->AsText);
ok(is_deeply($p, $q), "bootstrap via Text");

#print STDERR $P->AsText,"\n";
my $Q = Geo::OGC::Geometry->new(Text => $P->AsText);
ok(is_deeply($P, $Q), "bootstrap multipolygon via Text");

$C = new Geo::OGC::GeometryCollection;
$C->AddGeometry(Geo::OGC::Point->new(0, 0));
$C->AddGeometry($p);
#print STDERR $C->AsText,"\n";
$D = Geo::OGC::Geometry->new(Text => $C->AsText);
ok(is_deeply($C, $D), "bootstrap collection via Text");

$Q = $P->Clone;
ok(is_deeply($P, $Q), "clone polygon");

$D = $C->Clone;
ok(is_deeply($C, $D), "clone collection");

$p = Geo::OGC::Point->new(1, 1);
$p->ApplyTransformation
    ( sub {
	my($x, $y, $z) = @_;
	$x += 2;
	$y -= 2;
	return ($x, $y, $z);
     }
);
ok($p->Equals(Geo::OGC::Point->new(3, -1)), "transformation");

my $r2 = new Geo::OGC::LinearRing(points => [[0, 0], [1, 0], [1, 1], [0, 1], [0, 0]]);
ok(is_deeply($r, $r2), "curve constructor params");

$p = Geo::OGC::Point->new(123.456, 654.321);
$q = Geo::OGC::Point->new(123.5, 654.32);
$r = Geo::OGC::Point->new(120, 650);
ok(!$p->Equals($q), "no precision a");
ok(!$p->Equals($r), "no precision b");
$p->Precision(4);
#print STDERR $p->AsText,"\n";
ok($p->Equals($q), "precision 4 a");
ok(!$p->Equals($r), "precision 4 b");
$p->Precision(2);
#print STDERR $p->AsText,"\n";
ok($p->Equals($q), "precision 2 a");
ok($p->Equals($r), "precision 2 b");

