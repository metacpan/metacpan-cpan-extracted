use v5.10;
use strict;
use warnings;
use Carp;
use Encode qw(decode encode);
use Geo::GDAL::FFI;
use Test::More;
use Data::Dumper;
use JSON;
use FFI::Platypus::Buffer;

my $gdal = Geo::GDAL::FFI->new();

{
    my $geometry = Geo::GDAL::FFI::Geometry->new(WKT => 'POINT(1 1)');
    ok($geometry->GetType eq 'Point', "Create Point from WKT (1).");
    ok($geometry->AsText eq 'POINT (1 1)', "Create point from WKT (2).");
}

{
    my $geometry = Geo::GDAL::FFI::Geometry->new(WKT => 'POINTM(1 2 3)');
    my $type = $geometry->GetType;
    ok($type eq 'PointM', "Create PointM from WKT: $type");
    my $wkt = $geometry->AsText;
    ok($wkt eq 'POINT M (1 2 3)', "Create point from WKT: $wkt");
}

{
    my $g = Geo::GDAL::FFI::Geometry->new('Point');
    $g->SetPoint(5, 8);
    my @p = $g->GetPoint;
    ok($p[0] == 5, "Set/GetPoint");
}

{
    my $geometry = Geo::GDAL::FFI::Geometry->new(WKT => 'POINT(1 1)');
    my $c = $geometry->Centroid;
    ok($geometry->AsText eq 'POINT (1 1)', "Centroid");
}

{
    my $g = Geo::GDAL::FFI::Geometry->new(WKT => 'POLYHEDRALSURFACE Z ( '.
    '((0 0 0, 0 1 0, 1 1 0, 1 0 0, 0 0 0)), '.
    '((0 0 0, 0 1 0, 0 1 1, 0 0 1, 0 0 0)), '.
    '((0 0 0, 1 0 0, 1 0 1, 0 0 1, 0 0 0)), '.
    '((1 1 1, 1 0 1, 0 0 1, 0 1 1, 1 1 1)), '.
    '((1 1 1, 1 0 1, 1 0 0, 1 1 0, 1 1 1)), '.
    '((1 1 1, 1 1 0, 0 1 0, 0 1 1, 1 1 1))) ');
    my $p = $g->GetPoints;
    ok(@$p == 6, "GetPoints");
    $p->[0][0][0][0] = 2;
    $g->SetPoints($p);
    $p = $g->GetPoints;
    ok($p->[0][0][0][0] == 2, "SetPoints");
}

done_testing();
