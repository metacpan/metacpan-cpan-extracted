# *-*-perl-*-*
use Test::More tests=>104;

BEGIN { use_ok( 'Geo::Approx' ); }
require_ok( 'Geo::Approx' );

my $obj = Geo::Approx->new();
$obj = Geo::Approx->new(32);

for(my $i=0;$i<100;$i++){
    my $digest1 = int(rand()*2**32);
    my ($lat,$lon) = $obj->int2latlon($digest1);
    my $digest2 = $obj->latlon2int($lat,$lon);
    ok($digest1==$digest2,'int2latlon is reversible');
}

ok($obj->latlon2int(-90,-180)==0,'zero');
ok($obj->latlon2int(90,179.999)==2**32-1,'inf');

