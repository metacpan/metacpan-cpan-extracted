use strict;
use warnings;
use Geo::Distance::XS;
use Test::More;

my @formulas = @Geo::Distance::XS::FORMULAS;
for my $f (@formulas) {
    my $geo = Geo::Distance->new;
    $geo->formula($f);

    my @coords = (-118.243103, 34.159545, -73.987427, 40.853293);
    my %expected = (
        map({ $_ => 2443 } @formulas), polar => 2766, tv => 2448, alt => 2448,
    );
    my $d = $geo->distance(mile => @coords);
    is int $d, $expected{$f}, "$f: distance from LA to NY";

    @coords = (175, 12, -5, -12);
    $d = $geo->distance(mile => @coords);
    ok $d == $d, "$f with antipodal coordinates is not NaN";
}

done_testing;
