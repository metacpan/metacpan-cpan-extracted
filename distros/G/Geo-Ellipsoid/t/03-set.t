#!perl
# Test Geo::Ellipsoid set

use strict;
use warnings;

use Test::More tests => 176;
use Test::Number::Delta relative => 1e-6;
use Geo::Ellipsoid;

my $e = Geo::Ellipsoid->new();

my $e1 = Geo::Ellipsoid->new();
$e->set_angle_unit('degrees');
$e1->set_angle_unit('degrees');
is( $e->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
is( $e1->{angle_unit}, 'degrees', 'angle unit is "degrees"' );

my $e2 = Geo::Ellipsoid->new();
$e->set_angle_unit('radians');
$e2->set_angle_unit('radians');
is( $e->{angle_unit}, 'radians', 'angle unit is "radians"' );
is( $e2->{angle_unit}, 'radians', 'angle unit is "radians"' );

my $e3 = Geo::Ellipsoid->new();
$e->set_angle_unit('DEG');
$e3->set_angle_unit('DEG');
is( $e->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
is( $e3->{angle_unit}, 'degrees', 'angle unit is "degrees"' );

my $e4 = Geo::Ellipsoid->new();
$e->set_angle_unit('Deg');
$e4->set_angle_unit('Deg');
is( $e->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
is( $e4->{angle_unit}, 'degrees', 'angle unit is "degrees"' );

my $e5 = Geo::Ellipsoid->new();
$e->set_angle_unit('deg');
$e5->set_angle_unit('deg');
is( $e->{angle_unit}, 'degrees', 'angle unit is "degrees"' );
is( $e5->{angle_unit}, 'degrees', 'angle unit is "degrees"' );

my $e6 = Geo::Ellipsoid->new();
$e->set_angle_unit('RAD');
$e6->set_angle_unit('RAD');
is( $e->{angle_unit}, 'radians', 'angle unit is "radians"' );
is( $e6->{angle_unit}, 'radians', 'angle unit is "radians"' );

my $e7 = Geo::Ellipsoid->new();
$e->set_angle_unit('Rad');
$e7->set_angle_unit('Rad');
is( $e->{angle_unit}, 'radians', 'angle unit is "radians"' );
is( $e7->{angle_unit}, 'radians', 'angle unit is "radians"' );

my $e8 = Geo::Ellipsoid->new();
$e->set_angle_unit('rad');
$e8->set_angle_unit('rad');
is( $e->{angle_unit}, 'radians', 'angle unit is "radians"' );
is( $e8->{angle_unit}, 'radians', 'angle unit is "radians"' );

my $e9 = Geo::Ellipsoid->new();
$e->set_ellipsoid('AIRY');
$e9->set_ellipsoid('AIRY');
is( $e->{ellipsoid}, 'AIRY', 'ellipsoid is "AIRY"' );
is( $e9->{ellipsoid}, 'AIRY', 'ellipsoid is "AIRY"' );
delta_ok( $e9->{equatorial}, 6377563.396,
    'equatorial radius is with tolerance' );
delta_ok( $e9->{polar}, 6356256.90923729,
    'polar radius is with tolerance' );
delta_ok( $e9->{flattening}, 0.00334085064149708,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6377563.396,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356256.90923729,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00334085064149708,
    'flattening is with tolerance' );

my $e10 = Geo::Ellipsoid->new();
$e->set_ellipsoid('AIRY-MODIFIED');
$e10->set_ellipsoid('AIRY-MODIFIED');
is( $e->{ellipsoid}, 'AIRY-MODIFIED', 'ellipsoid is "AIRY-MODIFIED"' );
is( $e10->{ellipsoid}, 'AIRY-MODIFIED', 'ellipsoid is "AIRY-MODIFIED"' );
delta_ok( $e10->{equatorial}, 6377340.189,
    'equatorial radius is with tolerance' );
delta_ok( $e10->{polar}, 6356034.44793853,
    'polar radius is with tolerance' );
delta_ok( $e10->{flattening}, 0.00334085064149708,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6377340.189,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356034.44793853,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00334085064149708,
    'flattening is with tolerance' );

my $e11 = Geo::Ellipsoid->new();
$e->set_ellipsoid('AUSTRALIAN');
$e11->set_ellipsoid('AUSTRALIAN');
is( $e->{ellipsoid}, 'AUSTRALIAN', 'ellipsoid is "AUSTRALIAN"' );
is( $e11->{ellipsoid}, 'AUSTRALIAN', 'ellipsoid is "AUSTRALIAN"' );
delta_ok( $e11->{equatorial}, 6378160,
    'equatorial radius is with tolerance' );
delta_ok( $e11->{polar}, 6356774.71919531,
    'polar radius is with tolerance' );
delta_ok( $e11->{flattening}, 0.00335289186923722,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6378160,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356774.71919531,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00335289186923722,
    'flattening is with tolerance' );

my $e12 = Geo::Ellipsoid->new();
$e->set_ellipsoid('BESSEL-1841');
$e12->set_ellipsoid('BESSEL-1841');
is( $e->{ellipsoid}, 'BESSEL-1841', 'ellipsoid is "BESSEL-1841"' );
is( $e12->{ellipsoid}, 'BESSEL-1841', 'ellipsoid is "BESSEL-1841"' );
delta_ok( $e12->{equatorial}, 6377397.155,
    'equatorial radius is with tolerance' );
delta_ok( $e12->{polar}, 6356078.96281819,
    'polar radius is with tolerance' );
delta_ok( $e12->{flattening}, 0.00334277318217481,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6377397.155,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356078.96281819,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00334277318217481,
    'flattening is with tolerance' );

my $e13 = Geo::Ellipsoid->new();
$e->set_ellipsoid('CLARKE-1880');
$e13->set_ellipsoid('CLARKE-1880');
is( $e->{ellipsoid}, 'CLARKE-1880', 'ellipsoid is "CLARKE-1880"' );
is( $e13->{ellipsoid}, 'CLARKE-1880', 'ellipsoid is "CLARKE-1880"' );
delta_ok( $e13->{equatorial}, 6378249.145,
    'equatorial radius is with tolerance' );
delta_ok( $e13->{polar}, 6356514.86954978,
    'polar radius is with tolerance' );
delta_ok( $e13->{flattening}, 0.00340756137869933,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6378249.145,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356514.86954978,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00340756137869933,
    'flattening is with tolerance' );

my $e14 = Geo::Ellipsoid->new();
$e->set_ellipsoid('EVEREST-1830');
$e14->set_ellipsoid('EVEREST-1830');
is( $e->{ellipsoid}, 'EVEREST-1830', 'ellipsoid is "EVEREST-1830"' );
is( $e14->{ellipsoid}, 'EVEREST-1830', 'ellipsoid is "EVEREST-1830"' );
delta_ok( $e14->{equatorial}, 6377276.345,
    'equatorial radius is with tolerance' );
delta_ok( $e14->{polar}, 6356075.41314024,
    'polar radius is with tolerance' );
delta_ok( $e14->{flattening}, 0.00332444929666288,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6377276.345,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356075.41314024,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00332444929666288,
    'flattening is with tolerance' );

my $e15 = Geo::Ellipsoid->new();
$e->set_ellipsoid('EVEREST-MODIFIED');
$e15->set_ellipsoid('EVEREST-MODIFIED');
is( $e->{ellipsoid}, 'EVEREST-MODIFIED', 'ellipsoid is "EVEREST-MODIFIED"' );
is( $e15->{ellipsoid}, 'EVEREST-MODIFIED', 'ellipsoid is "EVEREST-MODIFIED"' );
delta_ok( $e15->{equatorial}, 6377304.063,
    'equatorial radius is with tolerance' );
delta_ok( $e15->{polar}, 6356103.03899315,
    'polar radius is with tolerance' );
delta_ok( $e15->{flattening}, 0.00332444929666288,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6377304.063,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356103.03899315,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00332444929666288,
    'flattening is with tolerance' );

my $e16 = Geo::Ellipsoid->new();
$e->set_ellipsoid('FISHER-1960');
$e16->set_ellipsoid('FISHER-1960');
is( $e->{ellipsoid}, 'FISHER-1960', 'ellipsoid is "FISHER-1960"' );
is( $e16->{ellipsoid}, 'FISHER-1960', 'ellipsoid is "FISHER-1960"' );
delta_ok( $e16->{equatorial}, 6378166,
    'equatorial radius is with tolerance' );
delta_ok( $e16->{polar}, 6356784.28360711,
    'polar radius is with tolerance' );
delta_ok( $e16->{flattening}, 0.00335232986925913,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6378166,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356784.28360711,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00335232986925913,
    'flattening is with tolerance' );

my $e17 = Geo::Ellipsoid->new();
$e->set_ellipsoid('FISHER-1968');
$e17->set_ellipsoid('FISHER-1968');
is( $e->{ellipsoid}, 'FISHER-1968', 'ellipsoid is "FISHER-1968"' );
is( $e17->{ellipsoid}, 'FISHER-1968', 'ellipsoid is "FISHER-1968"' );
delta_ok( $e17->{equatorial}, 6378150,
    'equatorial radius is with tolerance' );
delta_ok( $e17->{polar}, 6356768.33724438,
    'polar radius is with tolerance' );
delta_ok( $e17->{flattening}, 0.00335232986925913,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6378150,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356768.33724438,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00335232986925913,
    'flattening is with tolerance' );

my $e18 = Geo::Ellipsoid->new();
$e->set_ellipsoid('GRS80');
$e18->set_ellipsoid('GRS80');
is( $e->{ellipsoid}, 'GRS80', 'ellipsoid is "GRS80"' );
is( $e18->{ellipsoid}, 'GRS80', 'ellipsoid is "GRS80"' );
delta_ok( $e18->{equatorial}, 6378137,
    'equatorial radius is with tolerance' );
delta_ok( $e18->{polar}, 6356752.31414035,
    'polar radius is with tolerance' );
delta_ok( $e18->{flattening}, 0.00335281068118367,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6378137,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356752.31414035,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00335281068118367,
    'flattening is with tolerance' );

my $e19 = Geo::Ellipsoid->new();
$e->set_ellipsoid('HAYFORD');
$e19->set_ellipsoid('HAYFORD');
is( $e->{ellipsoid}, 'HAYFORD', 'ellipsoid is "HAYFORD"' );
is( $e19->{ellipsoid}, 'HAYFORD', 'ellipsoid is "HAYFORD"' );
delta_ok( $e19->{equatorial}, 6378388,
    'equatorial radius is with tolerance' );
delta_ok( $e19->{polar}, 6356911.94612795,
    'polar radius is with tolerance' );
delta_ok( $e19->{flattening}, 0.00336700336700337,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6378388,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356911.94612795,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00336700336700337,
    'flattening is with tolerance' );

my $e20 = Geo::Ellipsoid->new();
$e->set_ellipsoid('HOUGH-1956');
$e20->set_ellipsoid('HOUGH-1956');
is( $e->{ellipsoid}, 'HOUGH-1956', 'ellipsoid is "HOUGH-1956"' );
is( $e20->{ellipsoid}, 'HOUGH-1956', 'ellipsoid is "HOUGH-1956"' );
delta_ok( $e20->{equatorial}, 6378270,
    'equatorial radius is with tolerance' );
delta_ok( $e20->{polar}, 6356794.34343434,
    'polar radius is with tolerance' );
delta_ok( $e20->{flattening}, 0.00336700336700337,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6378270,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356794.34343434,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00336700336700337,
    'flattening is with tolerance' );

my $e21 = Geo::Ellipsoid->new();
$e->set_ellipsoid('IAU76');
$e21->set_ellipsoid('IAU76');
is( $e->{ellipsoid}, 'IAU76', 'ellipsoid is "IAU76"' );
is( $e21->{ellipsoid}, 'IAU76', 'ellipsoid is "IAU76"' );
delta_ok( $e21->{equatorial}, 6378140,
    'equatorial radius is with tolerance' );
delta_ok( $e21->{polar}, 6356755.28815753,
    'polar radius is with tolerance' );
delta_ok( $e21->{flattening}, 0.00335281317789691,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6378140,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356755.28815753,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00335281317789691,
    'flattening is with tolerance' );

my $e22 = Geo::Ellipsoid->new();
$e->set_ellipsoid('KRASSOVSKY-1938');
$e22->set_ellipsoid('KRASSOVSKY-1938');
is( $e->{ellipsoid}, 'KRASSOVSKY-1938', 'ellipsoid is "KRASSOVSKY-1938"' );
is( $e22->{ellipsoid}, 'KRASSOVSKY-1938', 'ellipsoid is "KRASSOVSKY-1938"' );
delta_ok( $e22->{equatorial}, 6378245,
    'equatorial radius is with tolerance' );
delta_ok( $e22->{polar}, 6356863.01877305,
    'polar radius is with tolerance' );
delta_ok( $e22->{flattening}, 0.00335232986925913,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6378245,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356863.01877305,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00335232986925913,
    'flattening is with tolerance' );

my $e23 = Geo::Ellipsoid->new();
$e->set_ellipsoid('NAD27');
$e23->set_ellipsoid('NAD27');
is( $e->{ellipsoid}, 'NAD27', 'ellipsoid is "NAD27"' );
is( $e23->{ellipsoid}, 'NAD27', 'ellipsoid is "NAD27"' );
delta_ok( $e23->{equatorial}, 6378206.4,
    'equatorial radius is with tolerance' );
delta_ok( $e23->{polar}, 6356583.79999999,
    'polar radius is with tolerance' );
delta_ok( $e23->{flattening}, 0.00339007530392992,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6378206.4,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356583.79999999,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00339007530392992,
    'flattening is with tolerance' );

my $e24 = Geo::Ellipsoid->new();
$e->set_ellipsoid('NWL-9D');
$e24->set_ellipsoid('NWL-9D');
is( $e->{ellipsoid}, 'NWL-9D', 'ellipsoid is "NWL-9D"' );
is( $e24->{ellipsoid}, 'NWL-9D', 'ellipsoid is "NWL-9D"' );
delta_ok( $e24->{equatorial}, 6378145,
    'equatorial radius is with tolerance' );
delta_ok( $e24->{polar}, 6356759.76948868,
    'polar radius is with tolerance' );
delta_ok( $e24->{flattening}, 0.00335289186923722,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6378145,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356759.76948868,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00335289186923722,
    'flattening is with tolerance' );

my $e25 = Geo::Ellipsoid->new();
$e->set_ellipsoid('SOUTHAMERICAN-1969');
$e25->set_ellipsoid('SOUTHAMERICAN-1969');
is( $e->{ellipsoid}, 'SOUTHAMERICAN-1969', 'ellipsoid is "SOUTHAMERICAN-1969"' );
is( $e25->{ellipsoid}, 'SOUTHAMERICAN-1969', 'ellipsoid is "SOUTHAMERICAN-1969"' );
delta_ok( $e25->{equatorial}, 6378160,
    'equatorial radius is with tolerance' );
delta_ok( $e25->{polar}, 6356774.71919531,
    'polar radius is with tolerance' );
delta_ok( $e25->{flattening}, 0.00335289186923722,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6378160,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356774.71919531,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00335289186923722,
    'flattening is with tolerance' );

my $e26 = Geo::Ellipsoid->new();
$e->set_ellipsoid('SOVIET-1985');
$e26->set_ellipsoid('SOVIET-1985');
is( $e->{ellipsoid}, 'SOVIET-1985', 'ellipsoid is "SOVIET-1985"' );
is( $e26->{ellipsoid}, 'SOVIET-1985', 'ellipsoid is "SOVIET-1985"' );
delta_ok( $e26->{equatorial}, 6378136,
    'equatorial radius is with tolerance' );
delta_ok( $e26->{polar}, 6356751.30156878,
    'polar radius is with tolerance' );
delta_ok( $e26->{flattening}, 0.00335281317789691,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6378136,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356751.30156878,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00335281317789691,
    'flattening is with tolerance' );

my $e27 = Geo::Ellipsoid->new();
$e->set_ellipsoid('WGS72');
$e27->set_ellipsoid('WGS72');
is( $e->{ellipsoid}, 'WGS72', 'ellipsoid is "WGS72"' );
is( $e27->{ellipsoid}, 'WGS72', 'ellipsoid is "WGS72"' );
delta_ok( $e27->{equatorial}, 6378135,
    'equatorial radius is with tolerance' );
delta_ok( $e27->{polar}, 6356750.52001609,
    'polar radius is with tolerance' );
delta_ok( $e27->{flattening}, 0.0033527794541675,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6378135,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356750.52001609,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.0033527794541675,
    'flattening is with tolerance' );

my $e28 = Geo::Ellipsoid->new();
$e->set_ellipsoid('WGS84');
$e28->set_ellipsoid('WGS84');
is( $e->{ellipsoid}, 'WGS84', 'ellipsoid is "WGS84"' );
is( $e28->{ellipsoid}, 'WGS84', 'ellipsoid is "WGS84"' );
delta_ok( $e28->{equatorial}, 6378137,
    'equatorial radius is with tolerance' );
delta_ok( $e28->{polar}, 6356752.31424518,
    'polar radius is with tolerance' );
delta_ok( $e28->{flattening}, 0.00335281066474748,
    'flattening is with tolerance' );
delta_ok( $e->{equatorial}, 6378137,
    'equatorial radius is with tolerance' );
delta_ok( $e->{polar}, 6356752.31424518,
    'polar radius is with tolerance' );
delta_ok( $e->{flattening}, 0.00335281066474748,
    'flattening is with tolerance' );
