#!perl
# Test Geo::Ellipsoid create

use strict;
use warnings;

use Test::More tests => 154;
use Test::Number::Delta relative => 1e-6;
use Geo::Ellipsoid;

my $e1 = Geo::Ellipsoid->new(ell => 'AIRY');
isnt( $e1, undef, 'object is defined' );
isa_ok( $e1, 'Geo::Ellipsoid' );
is( $e1->{ellipsoid}, 'AIRY',
    'ellipsoid is "AIRY"' );
delta_ok( $e1->{equatorial}, 6377563.396,
    'equatorial radius is within tolerance' );
delta_ok( $e1->{polar}, 6356256.90923729,
    'polar radius is within tolerance' );
delta_ok( $e1->{flattening}, 0.00334085064149708,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'AIRY'}, 'ellipsoid "AIRY" exists' );

my $e2 = Geo::Ellipsoid->new(ell => 'AIRY-MODIFIED');
isnt( $e2, undef, 'object is defined' );
isa_ok( $e2, 'Geo::Ellipsoid' );
is( $e2->{ellipsoid}, 'AIRY-MODIFIED',
    'ellipsoid is "AIRY-MODIFIED"' );
delta_ok( $e2->{equatorial}, 6377340.189,
    'equatorial radius is within tolerance' );
delta_ok( $e2->{polar}, 6356034.44793853,
    'polar radius is within tolerance' );
delta_ok( $e2->{flattening}, 0.00334085064149708,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'AIRY-MODIFIED'}, 'ellipsoid "AIRY-MODIFIED" exists' );

my $e3 = Geo::Ellipsoid->new(ell => 'AUSTRALIAN');
isnt( $e3, undef, 'object is defined' );
isa_ok( $e3, 'Geo::Ellipsoid' );
is( $e3->{ellipsoid}, 'AUSTRALIAN',
    'ellipsoid is "AUSTRALIAN"' );
delta_ok( $e3->{equatorial}, 6378160,
    'equatorial radius is within tolerance' );
delta_ok( $e3->{polar}, 6356774.71919531,
    'polar radius is within tolerance' );
delta_ok( $e3->{flattening}, 0.00335289186923722,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'AUSTRALIAN'}, 'ellipsoid "AUSTRALIAN" exists' );

my $e4 = Geo::Ellipsoid->new(ell => 'BESSEL-1841');
isnt( $e4, undef, 'object is defined' );
isa_ok( $e4, 'Geo::Ellipsoid' );
is( $e4->{ellipsoid}, 'BESSEL-1841',
    'ellipsoid is "BESSEL-1841"' );
delta_ok( $e4->{equatorial}, 6377397.155,
    'equatorial radius is within tolerance' );
delta_ok( $e4->{polar}, 6356078.96281819,
    'polar radius is within tolerance' );
delta_ok( $e4->{flattening}, 0.00334277318217481,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'BESSEL-1841'}, 'ellipsoid "BESSEL-1841" exists' );

my $e5 = Geo::Ellipsoid->new(ell => 'CLARKE-1880');
isnt( $e5, undef, 'object is defined' );
isa_ok( $e5, 'Geo::Ellipsoid' );
is( $e5->{ellipsoid}, 'CLARKE-1880',
    'ellipsoid is "CLARKE-1880"' );
delta_ok( $e5->{equatorial}, 6378249.145,
    'equatorial radius is within tolerance' );
delta_ok( $e5->{polar}, 6356514.86954978,
    'polar radius is within tolerance' );
delta_ok( $e5->{flattening}, 0.00340756137869933,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'CLARKE-1880'}, 'ellipsoid "CLARKE-1880" exists' );

my $e6 = Geo::Ellipsoid->new(ell => 'EVEREST-1830');
isnt( $e6, undef, 'object is defined' );
isa_ok( $e6, 'Geo::Ellipsoid' );
is( $e6->{ellipsoid}, 'EVEREST-1830',
    'ellipsoid is "EVEREST-1830"' );
delta_ok( $e6->{equatorial}, 6377276.345,
    'equatorial radius is within tolerance' );
delta_ok( $e6->{polar}, 6356075.41314024,
    'polar radius is within tolerance' );
delta_ok( $e6->{flattening}, 0.00332444929666288,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'EVEREST-1830'}, 'ellipsoid "EVEREST-1830" exists' );

my $e7 = Geo::Ellipsoid->new(ell => 'EVEREST-MODIFIED');
isnt( $e7, undef, 'object is defined' );
isa_ok( $e7, 'Geo::Ellipsoid' );
is( $e7->{ellipsoid}, 'EVEREST-MODIFIED',
    'ellipsoid is "EVEREST-MODIFIED"' );
delta_ok( $e7->{equatorial}, 6377304.063,
    'equatorial radius is within tolerance' );
delta_ok( $e7->{polar}, 6356103.03899315,
    'polar radius is within tolerance' );
delta_ok( $e7->{flattening}, 0.00332444929666288,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'EVEREST-MODIFIED'}, 'ellipsoid "EVEREST-MODIFIED" exists' );

my $e8 = Geo::Ellipsoid->new(ell => 'FISHER-1960');
isnt( $e8, undef, 'object is defined' );
isa_ok( $e8, 'Geo::Ellipsoid' );
is( $e8->{ellipsoid}, 'FISHER-1960',
    'ellipsoid is "FISHER-1960"' );
delta_ok( $e8->{equatorial}, 6378166,
    'equatorial radius is within tolerance' );
delta_ok( $e8->{polar}, 6356784.28360711,
    'polar radius is within tolerance' );
delta_ok( $e8->{flattening}, 0.00335232986925913,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'FISHER-1960'}, 'ellipsoid "FISHER-1960" exists' );

my $e9 = Geo::Ellipsoid->new(ell => 'FISHER-1968');
isnt( $e9, undef, 'object is defined' );
isa_ok( $e9, 'Geo::Ellipsoid' );
is( $e9->{ellipsoid}, 'FISHER-1968',
    'ellipsoid is "FISHER-1968"' );
delta_ok( $e9->{equatorial}, 6378150,
    'equatorial radius is within tolerance' );
delta_ok( $e9->{polar}, 6356768.33724438,
    'polar radius is within tolerance' );
delta_ok( $e9->{flattening}, 0.00335232986925913,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'FISHER-1968'}, 'ellipsoid "FISHER-1968" exists' );

my $e10 = Geo::Ellipsoid->new(ell => 'GRS80');
isnt( $e10, undef, 'object is defined' );
isa_ok( $e10, 'Geo::Ellipsoid' );
is( $e10->{ellipsoid}, 'GRS80',
    'ellipsoid is "GRS80"' );
delta_ok( $e10->{equatorial}, 6378137,
    'equatorial radius is within tolerance' );
delta_ok( $e10->{polar}, 6356752.31414035,
    'polar radius is within tolerance' );
delta_ok( $e10->{flattening}, 0.00335281068118367,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'GRS80'}, 'ellipsoid "GRS80" exists' );

my $e11 = Geo::Ellipsoid->new(ell => 'HAYFORD');
isnt( $e11, undef, 'object is defined' );
isa_ok( $e11, 'Geo::Ellipsoid' );
is( $e11->{ellipsoid}, 'HAYFORD',
    'ellipsoid is "HAYFORD"' );
delta_ok( $e11->{equatorial}, 6378388,
    'equatorial radius is within tolerance' );
delta_ok( $e11->{polar}, 6356911.94612795,
    'polar radius is within tolerance' );
delta_ok( $e11->{flattening}, 0.00336700336700337,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'HAYFORD'}, 'ellipsoid "HAYFORD" exists' );

my $e12 = Geo::Ellipsoid->new(ell => 'HOUGH-1956');
isnt( $e12, undef, 'object is defined' );
isa_ok( $e12, 'Geo::Ellipsoid' );
is( $e12->{ellipsoid}, 'HOUGH-1956',
    'ellipsoid is "HOUGH-1956"' );
delta_ok( $e12->{equatorial}, 6378270,
    'equatorial radius is within tolerance' );
delta_ok( $e12->{polar}, 6356794.34343434,
    'polar radius is within tolerance' );
delta_ok( $e12->{flattening}, 0.00336700336700337,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'HOUGH-1956'}, 'ellipsoid "HOUGH-1956" exists' );

my $e13 = Geo::Ellipsoid->new(ell => 'IAU76');
isnt( $e13, undef, 'object is defined' );
isa_ok( $e13, 'Geo::Ellipsoid' );
is( $e13->{ellipsoid}, 'IAU76',
    'ellipsoid is "IAU76"' );
delta_ok( $e13->{equatorial}, 6378140,
    'equatorial radius is within tolerance' );
delta_ok( $e13->{polar}, 6356755.28815753,
    'polar radius is within tolerance' );
delta_ok( $e13->{flattening}, 0.00335281317789691,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'IAU76'}, 'ellipsoid "IAU76" exists' );

my $e14 = Geo::Ellipsoid->new(ell => 'KRASSOVSKY-1938');
isnt( $e14, undef, 'object is defined' );
isa_ok( $e14, 'Geo::Ellipsoid' );
is( $e14->{ellipsoid}, 'KRASSOVSKY-1938',
    'ellipsoid is "KRASSOVSKY-1938"' );
delta_ok( $e14->{equatorial}, 6378245,
    'equatorial radius is within tolerance' );
delta_ok( $e14->{polar}, 6356863.01877305,
    'polar radius is within tolerance' );
delta_ok( $e14->{flattening}, 0.00335232986925913,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'KRASSOVSKY-1938'}, 'ellipsoid "KRASSOVSKY-1938" exists' );

my $e15 = Geo::Ellipsoid->new(ell => 'NAD27');
isnt( $e15, undef, 'object is defined' );
isa_ok( $e15, 'Geo::Ellipsoid' );
is( $e15->{ellipsoid}, 'NAD27',
    'ellipsoid is "NAD27"' );
delta_ok( $e15->{equatorial}, 6378206.4,
    'equatorial radius is within tolerance' );
delta_ok( $e15->{polar}, 6356583.79999999,
    'polar radius is within tolerance' );
delta_ok( $e15->{flattening}, 0.00339007530392992,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'NAD27'}, 'ellipsoid "NAD27" exists' );

my $e16 = Geo::Ellipsoid->new(ell => 'NWL-9D');
isnt( $e16, undef, 'object is defined' );
isa_ok( $e16, 'Geo::Ellipsoid' );
is( $e16->{ellipsoid}, 'NWL-9D',
    'ellipsoid is "NWL-9D"' );
delta_ok( $e16->{equatorial}, 6378145,
    'equatorial radius is within tolerance' );
delta_ok( $e16->{polar}, 6356759.76948868,
    'polar radius is within tolerance' );
delta_ok( $e16->{flattening}, 0.00335289186923722,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'NWL-9D'}, 'ellipsoid "NWL-9D" exists' );

my $e17 = Geo::Ellipsoid->new(ell => 'SOUTHAMERICAN-1969');
isnt( $e17, undef, 'object is defined' );
isa_ok( $e17, 'Geo::Ellipsoid' );
is( $e17->{ellipsoid}, 'SOUTHAMERICAN-1969',
    'ellipsoid is "SOUTHAMERICAN-1969"' );
delta_ok( $e17->{equatorial}, 6378160,
    'equatorial radius is within tolerance' );
delta_ok( $e17->{polar}, 6356774.71919531,
    'polar radius is within tolerance' );
delta_ok( $e17->{flattening}, 0.00335289186923722,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'SOUTHAMERICAN-1969'}, 'ellipsoid "SOUTHAMERICAN-1969" exists' );

my $e18 = Geo::Ellipsoid->new(ell => 'SOVIET-1985');
isnt( $e18, undef, 'object is defined' );
isa_ok( $e18, 'Geo::Ellipsoid' );
is( $e18->{ellipsoid}, 'SOVIET-1985',
    'ellipsoid is "SOVIET-1985"' );
delta_ok( $e18->{equatorial}, 6378136,
    'equatorial radius is within tolerance' );
delta_ok( $e18->{polar}, 6356751.30156878,
    'polar radius is within tolerance' );
delta_ok( $e18->{flattening}, 0.00335281317789691,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'SOVIET-1985'}, 'ellipsoid "SOVIET-1985" exists' );

my $e19 = Geo::Ellipsoid->new(ell => 'WGS72');
isnt( $e19, undef, 'object is defined' );
isa_ok( $e19, 'Geo::Ellipsoid' );
is( $e19->{ellipsoid}, 'WGS72',
    'ellipsoid is "WGS72"' );
delta_ok( $e19->{equatorial}, 6378135,
    'equatorial radius is within tolerance' );
delta_ok( $e19->{polar}, 6356750.52001609,
    'polar radius is within tolerance' );
delta_ok( $e19->{flattening}, 0.0033527794541675,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'WGS72'}, 'ellipsoid "WGS72" exists' );

my $e20 = Geo::Ellipsoid->new(ell => 'WGS84');
isnt( $e20, undef, 'object is defined' );
isa_ok( $e20, 'Geo::Ellipsoid' );
is( $e20->{ellipsoid}, 'WGS84',
    'ellipsoid is "WGS84"' );
delta_ok( $e20->{equatorial}, 6378137,
    'equatorial radius is within tolerance' );
delta_ok( $e20->{polar}, 6356752.31424518,
    'polar radius is within tolerance' );
delta_ok( $e20->{flattening}, 0.00335281066474748,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'WGS84'}, 'ellipsoid "WGS84" exists' );

my $e21 = Geo::Ellipsoid->new();
$e21->set_custom_ellipsoid('CUSTOM',6378000,300);
isnt( $e21, undef, 'object is defined' );
isa_ok( $e21, 'Geo::Ellipsoid' );
is( $e21->{ellipsoid}, 'CUSTOM',
    'ellipsoid is "CUSTOM"' );
delta_ok( $e21->{equatorial}, 6378000,
    'equatorial radius is within tolerance' );
delta_ok( $e21->{polar}, 6356740,
    'polar radius is within tolerance' );
delta_ok( $e21->{flattening}, 0.00333333333333333,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'CUSTOM'}, 'ellipsoid "CUSTOM" exists' );

diag "\n\n\tWarning about 'Infinite flattening' OK here\n\n";
my $e22 = Geo::Ellipsoid->new();
$e22->set_custom_ellipsoid('sphere',6378137,0);
isnt( $e22, undef, 'object is defined' );
isa_ok( $e22, 'Geo::Ellipsoid' );
is( $e22->{ellipsoid}, 'SPHERE',
    'ellipsoid is "SPHERE"' );
delta_ok( $e22->{equatorial}, 6378137,
    'equatorial radius is within tolerance' );
delta_ok( $e22->{polar}, 6378137,
    'polar radius is within tolerance' );
delta_within( $e22->{flattening}, 0, 1e-6,
    'flattening is within tolerance' );
ok( exists $Geo::Ellipsoid::ellipsoids{'SPHERE'}, 'ellipsoid "SPHERE" exists' );
