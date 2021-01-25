#!perl
# Test Geo::Ellipsoid defaults

use strict;
use warnings;

use Test::More tests => 192;
use Test::Number::Delta relative => 1e-6;
use Geo::Ellipsoid;

my $e1 = Geo::Ellipsoid->new();
is( $e1->{ellipsoid}, 'WGS84' );
is( $e1->{angle_unit}, 'radians' );
is( $e1->{distance_unit}, 'meter' );
cmp_ok( $e1->{longitude_symmetric}, '==', 0 );
cmp_ok( $e1->{latitude_symmetric}, '==', 1 );
cmp_ok( $e1->{bearing_symmetric}, '==', 0 );
$e1->set_defaults(
  ellipsoid => 'NAD27',
  angle_unit => 'degrees',
  distance_unit => 'kilometer',
  longitude_symmetric => 1,
  bearing_symmetric => 1
);
my $e2 = Geo::Ellipsoid->new();
is( $e2->{ellipsoid}, 'NAD27' );
is( $e2->{angle_unit}, 'degrees' );
is( $e2->{distance_unit}, 'kilometer' );
cmp_ok( $e2->{longitude_symmetric}, '==', 1 );
cmp_ok( $e2->{latitude_symmetric}, '==', 1 );
cmp_ok( $e2->{bearing_symmetric}, '==', 1 );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'AIRY');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'AIRY',
    'default ellipsoid is "AIRY"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e3 = Geo::Ellipsoid->new();
isnt( $e3, undef, 'object is defined' );
isa_ok( $e3, 'Geo::Ellipsoid' );
is( $e3->{ellipsoid}, 'AIRY', 'ellipsoid is "AIRY"' );
is( $e3->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e3->{equatorial}, 6377563.396,
    'equatorial radius is within tolerance' );
delta_ok( $e3->{polar}, 6356256.90923729,
    'polar radius is within tolerance' );
delta_ok( $e3->{flattening}, 0.00334085064149708,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'AIRY-MODIFIED');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'AIRY-MODIFIED',
    'default ellipsoid is "AIRY-MODIFIED"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e4 = Geo::Ellipsoid->new();
isnt( $e4, undef, 'object is defined' );
isa_ok( $e4, 'Geo::Ellipsoid' );
is( $e4->{ellipsoid}, 'AIRY-MODIFIED', 'ellipsoid is "AIRY-MODIFIED"' );
is( $e4->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e4->{equatorial}, 6377340.189,
    'equatorial radius is within tolerance' );
delta_ok( $e4->{polar}, 6356034.44793853,
    'polar radius is within tolerance' );
delta_ok( $e4->{flattening}, 0.00334085064149708,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'AUSTRALIAN');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'AUSTRALIAN',
    'default ellipsoid is "AUSTRALIAN"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e5 = Geo::Ellipsoid->new();
isnt( $e5, undef, 'object is defined' );
isa_ok( $e5, 'Geo::Ellipsoid' );
is( $e5->{ellipsoid}, 'AUSTRALIAN', 'ellipsoid is "AUSTRALIAN"' );
is( $e5->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e5->{equatorial}, 6378160,
    'equatorial radius is within tolerance' );
delta_ok( $e5->{polar}, 6356774.71919531,
    'polar radius is within tolerance' );
delta_ok( $e5->{flattening}, 0.00335289186923722,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'BESSEL-1841');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'BESSEL-1841',
    'default ellipsoid is "BESSEL-1841"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e6 = Geo::Ellipsoid->new();
isnt( $e6, undef, 'object is defined' );
isa_ok( $e6, 'Geo::Ellipsoid' );
is( $e6->{ellipsoid}, 'BESSEL-1841', 'ellipsoid is "BESSEL-1841"' );
is( $e6->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e6->{equatorial}, 6377397.155,
    'equatorial radius is within tolerance' );
delta_ok( $e6->{polar}, 6356078.96281819,
    'polar radius is within tolerance' );
delta_ok( $e6->{flattening}, 0.00334277318217481,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'CLARKE-1880');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'CLARKE-1880',
    'default ellipsoid is "CLARKE-1880"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e7 = Geo::Ellipsoid->new();
isnt( $e7, undef, 'object is defined' );
isa_ok( $e7, 'Geo::Ellipsoid' );
is( $e7->{ellipsoid}, 'CLARKE-1880', 'ellipsoid is "CLARKE-1880"' );
is( $e7->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e7->{equatorial}, 6378249.145,
    'equatorial radius is within tolerance' );
delta_ok( $e7->{polar}, 6356514.86954978,
    'polar radius is within tolerance' );
delta_ok( $e7->{flattening}, 0.00340756137869933,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'EVEREST-1830');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'EVEREST-1830',
    'default ellipsoid is "EVEREST-1830"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e8 = Geo::Ellipsoid->new();
isnt( $e8, undef, 'object is defined' );
isa_ok( $e8, 'Geo::Ellipsoid' );
is( $e8->{ellipsoid}, 'EVEREST-1830', 'ellipsoid is "EVEREST-1830"' );
is( $e8->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e8->{equatorial}, 6377276.345,
    'equatorial radius is within tolerance' );
delta_ok( $e8->{polar}, 6356075.41314024,
    'polar radius is within tolerance' );
delta_ok( $e8->{flattening}, 0.00332444929666288,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'EVEREST-MODIFIED');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'EVEREST-MODIFIED',
    'default ellipsoid is "EVEREST-MODIFIED"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e9 = Geo::Ellipsoid->new();
isnt( $e9, undef, 'object is defined' );
isa_ok( $e9, 'Geo::Ellipsoid' );
is( $e9->{ellipsoid}, 'EVEREST-MODIFIED', 'ellipsoid is "EVEREST-MODIFIED"' );
is( $e9->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e9->{equatorial}, 6377304.063,
    'equatorial radius is within tolerance' );
delta_ok( $e9->{polar}, 6356103.03899315,
    'polar radius is within tolerance' );
delta_ok( $e9->{flattening}, 0.00332444929666288,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'FISHER-1960');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'FISHER-1960',
    'default ellipsoid is "FISHER-1960"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e10 = Geo::Ellipsoid->new();
isnt( $e10, undef, 'object is defined' );
isa_ok( $e10, 'Geo::Ellipsoid' );
is( $e10->{ellipsoid}, 'FISHER-1960', 'ellipsoid is "FISHER-1960"' );
is( $e10->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e10->{equatorial}, 6378166,
    'equatorial radius is within tolerance' );
delta_ok( $e10->{polar}, 6356784.28360711,
    'polar radius is within tolerance' );
delta_ok( $e10->{flattening}, 0.00335232986925913,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'FISHER-1968');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'FISHER-1968',
    'default ellipsoid is "FISHER-1968"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e11 = Geo::Ellipsoid->new();
isnt( $e11, undef, 'object is defined' );
isa_ok( $e11, 'Geo::Ellipsoid' );
is( $e11->{ellipsoid}, 'FISHER-1968', 'ellipsoid is "FISHER-1968"' );
is( $e11->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e11->{equatorial}, 6378150,
    'equatorial radius is within tolerance' );
delta_ok( $e11->{polar}, 6356768.33724438,
    'polar radius is within tolerance' );
delta_ok( $e11->{flattening}, 0.00335232986925913,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'GRS80');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'GRS80',
    'default ellipsoid is "GRS80"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e12 = Geo::Ellipsoid->new();
isnt( $e12, undef, 'object is defined' );
isa_ok( $e12, 'Geo::Ellipsoid' );
is( $e12->{ellipsoid}, 'GRS80', 'ellipsoid is "GRS80"' );
is( $e12->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e12->{equatorial}, 6378137,
    'equatorial radius is within tolerance' );
delta_ok( $e12->{polar}, 6356752.31414035,
    'polar radius is within tolerance' );
delta_ok( $e12->{flattening}, 0.00335281068118367,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'HAYFORD');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'HAYFORD',
    'default ellipsoid is "HAYFORD"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e13 = Geo::Ellipsoid->new();
isnt( $e13, undef, 'object is defined' );
isa_ok( $e13, 'Geo::Ellipsoid' );
is( $e13->{ellipsoid}, 'HAYFORD', 'ellipsoid is "HAYFORD"' );
is( $e13->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e13->{equatorial}, 6378388,
    'equatorial radius is within tolerance' );
delta_ok( $e13->{polar}, 6356911.94612795,
    'polar radius is within tolerance' );
delta_ok( $e13->{flattening}, 0.00336700336700337,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'HOUGH-1956');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'HOUGH-1956',
    'default ellipsoid is "HOUGH-1956"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e14 = Geo::Ellipsoid->new();
isnt( $e14, undef, 'object is defined' );
isa_ok( $e14, 'Geo::Ellipsoid' );
is( $e14->{ellipsoid}, 'HOUGH-1956', 'ellipsoid is "HOUGH-1956"' );
is( $e14->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e14->{equatorial}, 6378270,
    'equatorial radius is within tolerance' );
delta_ok( $e14->{polar}, 6356794.34343434,
    'polar radius is within tolerance' );
delta_ok( $e14->{flattening}, 0.00336700336700337,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'IAU76');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'IAU76',
    'default ellipsoid is "IAU76"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e15 = Geo::Ellipsoid->new();
isnt( $e15, undef, 'object is defined' );
isa_ok( $e15, 'Geo::Ellipsoid' );
is( $e15->{ellipsoid}, 'IAU76', 'ellipsoid is "IAU76"' );
is( $e15->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e15->{equatorial}, 6378140,
    'equatorial radius is within tolerance' );
delta_ok( $e15->{polar}, 6356755.28815753,
    'polar radius is within tolerance' );
delta_ok( $e15->{flattening}, 0.00335281317789691,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'KRASSOVSKY-1938');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'KRASSOVSKY-1938',
    'default ellipsoid is "KRASSOVSKY-1938"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e16 = Geo::Ellipsoid->new();
isnt( $e16, undef, 'object is defined' );
isa_ok( $e16, 'Geo::Ellipsoid' );
is( $e16->{ellipsoid}, 'KRASSOVSKY-1938', 'ellipsoid is "KRASSOVSKY-1938"' );
is( $e16->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e16->{equatorial}, 6378245,
    'equatorial radius is within tolerance' );
delta_ok( $e16->{polar}, 6356863.01877305,
    'polar radius is within tolerance' );
delta_ok( $e16->{flattening}, 0.00335232986925913,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'NAD27');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'NAD27',
    'default ellipsoid is "NAD27"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e17 = Geo::Ellipsoid->new();
isnt( $e17, undef, 'object is defined' );
isa_ok( $e17, 'Geo::Ellipsoid' );
is( $e17->{ellipsoid}, 'NAD27', 'ellipsoid is "NAD27"' );
is( $e17->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e17->{equatorial}, 6378206.4,
    'equatorial radius is within tolerance' );
delta_ok( $e17->{polar}, 6356583.79999999,
    'polar radius is within tolerance' );
delta_ok( $e17->{flattening}, 0.00339007530392992,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'NWL-9D');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'NWL-9D',
    'default ellipsoid is "NWL-9D"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e18 = Geo::Ellipsoid->new();
isnt( $e18, undef, 'object is defined' );
isa_ok( $e18, 'Geo::Ellipsoid' );
is( $e18->{ellipsoid}, 'NWL-9D', 'ellipsoid is "NWL-9D"' );
is( $e18->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e18->{equatorial}, 6378145,
    'equatorial radius is within tolerance' );
delta_ok( $e18->{polar}, 6356759.76948868,
    'polar radius is within tolerance' );
delta_ok( $e18->{flattening}, 0.00335289186923722,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'SOUTHAMERICAN-1969');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'SOUTHAMERICAN-1969',
    'default ellipsoid is "SOUTHAMERICAN-1969"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e19 = Geo::Ellipsoid->new();
isnt( $e19, undef, 'object is defined' );
isa_ok( $e19, 'Geo::Ellipsoid' );
is( $e19->{ellipsoid}, 'SOUTHAMERICAN-1969', 'ellipsoid is "SOUTHAMERICAN-1969"' );
is( $e19->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e19->{equatorial}, 6378160,
    'equatorial radius is within tolerance' );
delta_ok( $e19->{polar}, 6356774.71919531,
    'polar radius is within tolerance' );
delta_ok( $e19->{flattening}, 0.00335289186923722,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'SOVIET-1985');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'SOVIET-1985',
    'default ellipsoid is "SOVIET-1985"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e20 = Geo::Ellipsoid->new();
isnt( $e20, undef, 'object is defined' );
isa_ok( $e20, 'Geo::Ellipsoid' );
is( $e20->{ellipsoid}, 'SOVIET-1985', 'ellipsoid is "SOVIET-1985"' );
is( $e20->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e20->{equatorial}, 6378136,
    'equatorial radius is within tolerance' );
delta_ok( $e20->{polar}, 6356751.30156878,
    'polar radius is within tolerance' );
delta_ok( $e20->{flattening}, 0.00335281317789691,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'WGS72');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'WGS72',
    'default ellipsoid is "WGS72"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e21 = Geo::Ellipsoid->new();
isnt( $e21, undef, 'object is defined' );
isa_ok( $e21, 'Geo::Ellipsoid' );
is( $e21->{ellipsoid}, 'WGS72', 'ellipsoid is "WGS72"' );
is( $e21->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e21->{equatorial}, 6378135,
    'equatorial radius is within tolerance' );
delta_ok( $e21->{polar}, 6356750.52001609,
    'polar radius is within tolerance' );
delta_ok( $e21->{flattening}, 0.0033527794541675,
    'flattening is within tolerance' );

Geo::Ellipsoid->set_defaults(angle_unit => 'degrees', ell => 'WGS84');
is( $Geo::Ellipsoid::defaults{ellipsoid}, 'WGS84',
    'default ellipsoid is "WGS84"' );
is( $Geo::Ellipsoid::defaults{angle_unit}, 'degrees',
    'default angle unit is "degrees"' );
my $e22 = Geo::Ellipsoid->new();
isnt( $e22, undef, 'object is defined' );
isa_ok( $e22, 'Geo::Ellipsoid' );
is( $e22->{ellipsoid}, 'WGS84', 'ellipsoid is "WGS84"' );
is( $e22->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
delta_ok( $e22->{equatorial}, 6378137,
    'equatorial radius is within tolerance' );
delta_ok( $e22->{polar}, 6356752.31424518,
    'polar radius is within tolerance' );
delta_ok( $e22->{flattening}, 0.00335281066474748,
    'flattening is within tolerance' );
