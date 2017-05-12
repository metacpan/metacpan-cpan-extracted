# Methods of Curve and LineString

use Test::More qw(no_plan);

BEGIN { 
    use_ok( 'Geo::OGC::Geometry' );
}
#goto here;
$c = new Geo::OGC::Curve;
$c->AddPoint(Geo::OGC::Point->new(0, 0));
$c->AddPoint(Geo::OGC::Point->new(1, 0));
$c->AddPoint(Geo::OGC::Point->new(1, 1));
$c->AddPoint(Geo::OGC::Point->new(0, 1));

$c->AddPoint(Geo::OGC::Point->new(2, 0), 1);
ok($c->PointN(1)->Equals(Geo::OGC::Point->new(2, 0)), "AddPoint 1 a");
ok($c->PointN(2)->Equals(Geo::OGC::Point->new(0, 0)), "AddPoint 1 b");
$c->DeletePoint(1);
ok($c->PointN(1)->Equals(Geo::OGC::Point->new(0, 0)), "DeletePoint 1");

$c->AddPoint(Geo::OGC::Point->new(2, 0), 2);
ok($c->PointN(2)->Equals(Geo::OGC::Point->new(2, 0)), "AddPoint 2 a");
ok($c->PointN(3)->Equals(Geo::OGC::Point->new(1, 0)), "AddPoint 2 b");
$c->DeletePoint(2);
ok($c->PointN(2)->Equals(Geo::OGC::Point->new(1, 0)), "DeletePoint 2");

$c->AddPoint(Geo::OGC::Point->new(2, 0), 4);
ok($c->PointN(4)->Equals(Geo::OGC::Point->new(2, 0)), "AddPoint 4 a");
ok($c->PointN(5)->Equals(Geo::OGC::Point->new(0, 1)), "AddPoint 4 b");
$c->DeletePoint(4);
ok($c->PointN(4)->Equals(Geo::OGC::Point->new(0, 1)), "DeletePoint 4");

bless $c, 'Geo::OGC::LineString';
ok($c->Length == 3, "Length");
ok($c->StartPoint->Equals(Geo::OGC::Point->new(0, 0)), "StartPoint");
ok($c->EndPoint->Equals(Geo::OGC::Point->new(0, 1)), "EndPoint");
ok($c->NumPoints == 4, "NumPoints");
ok(!$c->Is3D, "Is3D a");
$c->AddPoint(Geo::OGC::Point->new(2, 0, 3), 1);
ok($c->Is3D, "Is3D b");
$c->DeletePoint(1);

ok($c->IsSimple, "IsSimple a");
$c->AddPoint(Geo::OGC::Point->new(0.5, -1));
ok(!$c->IsSimple, "IsSimple b");
$c->DeletePoint(5);
ok($c->IsSimple, "IsSimple c");

ok(!$c->IsClosed, "IsClosed a");
$c->Close;
ok($c->IsClosed, "IsClosed b");

ok($c->IsRing(1), "IsRing");
ok($c->Area == 1, "Area");

$c = new Geo::OGC::LineString;
$c->AddPoint(Geo::OGC::Point->new(0, 0));
$c->AddPoint(Geo::OGC::Point->new(1, 0));
$c->AddPoint(Geo::OGC::Point->new(1, 1));
$c->Close;
ok($c->IsClosed, "IsClosed 3");
ok($c->IsSimple, "IsSimple 3");
ok($c->IsRing(1), "IsRing 3");
my @a = $c->Area;
ok($a[0] == 0.5, "Area 3");
$c->Reverse;
@a = $c->Area;
ok($a[0] == -0.5, "Area 3 b");

$c = new Geo::OGC::LineString;
$c->AddPoint(Geo::OGC::Point->new(0, 0));
$c->AddPoint(Geo::OGC::Point->new(1, 0));
$c->AddPoint(Geo::OGC::Point->new(1, 2));
$c->AddPoint(Geo::OGC::Point->new(1, 1));
$c->AddPoint(Geo::OGC::Point->new(2, 1));

ok(!$c->IsSimple, "IsSimple 4");

if (0) {
    print STDERR "\n";
    
    print STDERR Geo::OGC::Geometry::intersect(0,0, 1,0, -1,0, 0,0), "\n";
    print STDERR Geo::OGC::Geometry::intersect(0,0, 1,0,  0,1, 0,0), "\n";
    print STDERR Geo::OGC::Geometry::intersect(0,0, 1,0,  0,1, 0.5,0), "\n";
    print STDERR Geo::OGC::Geometry::intersect(0,0, 1,0,  0,1, 1,0), "\n";
    
    print STDERR Geo::OGC::Geometry::intersect(0,0, 1,0,  1,-1, 1,0), "\n";
    print STDERR Geo::OGC::Geometry::intersect(0,0, 1,0,  1,-1, 0.5,0), "\n";
    
    print STDERR Geo::OGC::Geometry::intersect(0,0, 1,0,  1,-1, 1,-0.5), "\n";
    
    print STDERR Geo::OGC::Geometry::intersect(0,0, 1,0,  -1,0, 0.5,0), "\n";
    print STDERR Geo::OGC::Geometry::intersect(0,0, 1,0,  -1,0, 1,0), "\n";

    print STDERR Geo::OGC::Geometry::intersect(0,0, 1,0,  0,0, 0,0), " point on line end\n";
    print STDERR Geo::OGC::Geometry::intersect(0,0, 1,0,  1,0, 1,0), " point on line end\n";
    print STDERR Geo::OGC::Geometry::intersect(0,0, 1,0,  0.5,0, 0.5,0), " point on line\n";
    print STDERR Geo::OGC::Geometry::intersect(0,0, 1,0,  0.5,1, 0.5,1), " point outside line\n";
}



my $p = new Geo::OGC::Polygon;
my $r = new Geo::OGC::LinearRing;
$r->AddPoint(Geo::OGC::Point->new(0, 0));
$r->AddPoint(Geo::OGC::Point->new(1, 1));
$r->AddPoint(Geo::OGC::Point->new(2, 3));
$r->AddPoint(Geo::OGC::Point->new(0, 2));
$r->AddPoint(Geo::OGC::Point->new(-1, 3));
$r->AddPoint(Geo::OGC::Point->new(-1, 4));
$r->AddPoint(Geo::OGC::Point->new(-0.5, 5));
$r->AddPoint(Geo::OGC::Point->new(-1.5, 6));
$r->AddPoint(Geo::OGC::Point->new(-3, 4));
$r->AddPoint(Geo::OGC::Point->new(-2, 2));
$r->Close;
$p->ExteriorRing($r);
#$p->AddInteriorRing(1);
eval {
    $p->Assert;
};
ok(!$@, "Polygon Assert a: $@");

$r = new Geo::OGC::LinearRing;
$r->AddPoint(Geo::OGC::Point->new(0, 0.5));
$r->AddPoint(Geo::OGC::Point->new(0.5, 1));
$r->AddPoint(Geo::OGC::Point->new(0, 2));
$r->AddPoint(Geo::OGC::Point->new(-0.5, 1));
$r->Close;
$p->AddInteriorRing($r);
eval {
    $p->Assert;
};
ok(!$@, "Polygon Assert b: $@");

$r = new Geo::OGC::LinearRing;
$r->AddPoint(Geo::OGC::Point->new(-3, 4));
$r->AddPoint(Geo::OGC::Point->new(-2.5, 4.5));
$r->AddPoint(Geo::OGC::Point->new(-2.5, 3.5));
$r->Close;
$p->AddInteriorRing($r);
eval {
    $p->Assert;
};
ok(!$@, "Polygon Assert c: $@");


here:
$c = new Geo::OGC::LineString;
$c->AddPoint(Geo::OGC::Point->new(0, 0));
$c->AddPoint(Geo::OGC::Point->new(1, 0));
$c->AddPoint(Geo::OGC::Point->new(1, 1));

$d = new Geo::OGC::LineString;
$d->AddPoint(Geo::OGC::Point->new(2, 0));
$d->AddPoint(Geo::OGC::Point->new(1, 0));
$d->AddPoint(Geo::OGC::Point->new(1, 1));
$d->AddPoint(Geo::OGC::Point->new(0, 0));
$d->AddPoint(Geo::OGC::Point->new(0.5, 0));

$i = $c->Intersection($d);

#print STDERR $i->AsText,"\n";
ok(@{$i->{Geometries}} == 2, "Intersection 1");

$g = Geo::OGC::Geometry->new(Text => 'Point(0,5 1.5)');
$g->{X} *= 3;
$g->{Y} *= 3;
ok($g->{X} == 1.5, "comma in WKT");

