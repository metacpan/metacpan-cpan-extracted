use 5.012;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Fatal;

use Geo::Geos::Coordinate;
use Geo::Geos::Algorithm;
use Geo::Geos::Algorithm qw/toRadians toDegrees angle isAcute isObtuse angleBetween angleBetweenOriented
                       interiorAngle normalize normalizePositive diff getTurn/;

subtest "Angle" => sub {
    my $r = toRadians(90);
    my $d = toDegrees($r);
    is $d, 90;

    my $c1 = Geo::Geos::Coordinate->new(0,2);
    my $c2 = Geo::Geos::Coordinate->new(0,0);
    my $c3 = Geo::Geos::Coordinate->new(1,1);

    like exception { angle(undef) }, qr/undef not allowed/;
    my $r2 = angle($c1);
    my $d2 = toDegrees($r2);
    is $d2, 90;

    ok isAcute($c1, $c2, $c3);
    ok !isObtuse($c1, $c2, $c3);

    my $r3 = angleBetween($c1, $c2, $c3);
    my $d3 = toDegrees($r3);
    is $d3, 45;

    my $r4 = angleBetweenOriented($c1, $c2, $c3);
    my $d4 = toDegrees($r4);
    is $d4, -45;

    my $r5 = interiorAngle($c1, $c2, $c3);
    my $d5 = toDegrees($r5);
    is $d5, 45;

    my $r6 = normalize($r * 3);
    my $d6 = toDegrees($r6);
    is $d6, -90;

    my $r7 = normalizePositive($r * 30);
    my $d7 = toDegrees($r7);
    ok abs($d7 -180) < 0.0000001;

    my $r8 = diff($r, $r * 10);
    my $d8 = toDegrees($r7);
    ok abs($d8 -180) < 0.0000001;

    is getTurn($r3, $r4), TYPE_TURN_CLOCKWISE;
};

done_testing;
