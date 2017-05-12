#!/usr/local/bin/perl
# Test Geo::Ellipsoid set
use Test::More tests => 176;
use Test::Number::Delta relative => 1e-6;
use Geo::Ellipsoid;
use blib;
use strict;
use warnings;

my $e = Geo::Ellipsoid->new();

my $e1 = Geo::Ellipsoid->new();
$e->set_units('degrees');
$e1->set_units('degrees');
ok( $e->{units} eq 'degrees' );
ok( $e1->{units} eq 'degrees' );

my $e2 = Geo::Ellipsoid->new();
$e->set_units('radians');
$e2->set_units('radians');
ok( $e->{units} eq 'radians' );
ok( $e2->{units} eq 'radians' );

my $e3 = Geo::Ellipsoid->new();
$e->set_units('DEG');
$e3->set_units('DEG');
ok( $e->{units} eq 'degrees' );
ok( $e3->{units} eq 'degrees' );

my $e4 = Geo::Ellipsoid->new();
$e->set_units('Deg');
$e4->set_units('Deg');
ok( $e->{units} eq 'degrees' );
ok( $e4->{units} eq 'degrees' );

my $e5 = Geo::Ellipsoid->new();
$e->set_units('deg');
$e5->set_units('deg');
ok( $e->{units} eq 'degrees' );
ok( $e5->{units} eq 'degrees' );

my $e6 = Geo::Ellipsoid->new();
$e->set_units('RAD');
$e6->set_units('RAD');
ok( $e->{units} eq 'radians' );
ok( $e6->{units} eq 'radians' );

my $e7 = Geo::Ellipsoid->new();
$e->set_units('Rad');
$e7->set_units('Rad');
ok( $e->{units} eq 'radians' );
ok( $e7->{units} eq 'radians' );

my $e8 = Geo::Ellipsoid->new();
$e->set_units('rad');
$e8->set_units('rad');
ok( $e->{units} eq 'radians' );
ok( $e8->{units} eq 'radians' );

my $e9 = Geo::Ellipsoid->new();
$e->set_ellipsoid('AIRY');
$e9->set_ellipsoid('AIRY');
ok( $e->{ellipsoid} eq 'AIRY' );
ok( $e9->{ellipsoid} eq 'AIRY' );
delta_ok( $e9->{equatorial}, 6377563.396 ); 
delta_ok( $e9->{polar}, 6356256.90923729 ); 
delta_ok( $e9->{flattening}, 0.00334085064149708 ); 
delta_ok( $e->{equatorial}, 6377563.396 ); 
delta_ok( $e->{polar}, 6356256.90923729 ); 
delta_ok( $e->{flattening}, 0.00334085064149708 ); 

my $e10 = Geo::Ellipsoid->new();
$e->set_ellipsoid('AIRY-MODIFIED');
$e10->set_ellipsoid('AIRY-MODIFIED');
ok( $e->{ellipsoid} eq 'AIRY-MODIFIED' );
ok( $e10->{ellipsoid} eq 'AIRY-MODIFIED' );
delta_ok( $e10->{equatorial}, 6377340.189 ); 
delta_ok( $e10->{polar}, 6356034.44793853 ); 
delta_ok( $e10->{flattening}, 0.00334085064149708 ); 
delta_ok( $e->{equatorial}, 6377340.189 ); 
delta_ok( $e->{polar}, 6356034.44793853 ); 
delta_ok( $e->{flattening}, 0.00334085064149708 ); 

my $e11 = Geo::Ellipsoid->new();
$e->set_ellipsoid('AUSTRALIAN');
$e11->set_ellipsoid('AUSTRALIAN');
ok( $e->{ellipsoid} eq 'AUSTRALIAN' );
ok( $e11->{ellipsoid} eq 'AUSTRALIAN' );
delta_ok( $e11->{equatorial}, 6378160 ); 
delta_ok( $e11->{polar}, 6356774.71919531 ); 
delta_ok( $e11->{flattening}, 0.00335289186923722 ); 
delta_ok( $e->{equatorial}, 6378160 ); 
delta_ok( $e->{polar}, 6356774.71919531 ); 
delta_ok( $e->{flattening}, 0.00335289186923722 ); 

my $e12 = Geo::Ellipsoid->new();
$e->set_ellipsoid('BESSEL-1841');
$e12->set_ellipsoid('BESSEL-1841');
ok( $e->{ellipsoid} eq 'BESSEL-1841' );
ok( $e12->{ellipsoid} eq 'BESSEL-1841' );
delta_ok( $e12->{equatorial}, 6377397.155 ); 
delta_ok( $e12->{polar}, 6356078.96281819 ); 
delta_ok( $e12->{flattening}, 0.00334277318217481 ); 
delta_ok( $e->{equatorial}, 6377397.155 ); 
delta_ok( $e->{polar}, 6356078.96281819 ); 
delta_ok( $e->{flattening}, 0.00334277318217481 ); 

my $e13 = Geo::Ellipsoid->new();
$e->set_ellipsoid('CLARKE-1880');
$e13->set_ellipsoid('CLARKE-1880');
ok( $e->{ellipsoid} eq 'CLARKE-1880' );
ok( $e13->{ellipsoid} eq 'CLARKE-1880' );
delta_ok( $e13->{equatorial}, 6378249.145 ); 
delta_ok( $e13->{polar}, 6356514.86954978 ); 
delta_ok( $e13->{flattening}, 0.00340756137869933 ); 
delta_ok( $e->{equatorial}, 6378249.145 ); 
delta_ok( $e->{polar}, 6356514.86954978 ); 
delta_ok( $e->{flattening}, 0.00340756137869933 ); 

my $e14 = Geo::Ellipsoid->new();
$e->set_ellipsoid('EVEREST-1830');
$e14->set_ellipsoid('EVEREST-1830');
ok( $e->{ellipsoid} eq 'EVEREST-1830' );
ok( $e14->{ellipsoid} eq 'EVEREST-1830' );
delta_ok( $e14->{equatorial}, 6377276.345 ); 
delta_ok( $e14->{polar}, 6356075.41314024 ); 
delta_ok( $e14->{flattening}, 0.00332444929666288 ); 
delta_ok( $e->{equatorial}, 6377276.345 ); 
delta_ok( $e->{polar}, 6356075.41314024 ); 
delta_ok( $e->{flattening}, 0.00332444929666288 ); 

my $e15 = Geo::Ellipsoid->new();
$e->set_ellipsoid('EVEREST-MODIFIED');
$e15->set_ellipsoid('EVEREST-MODIFIED');
ok( $e->{ellipsoid} eq 'EVEREST-MODIFIED' );
ok( $e15->{ellipsoid} eq 'EVEREST-MODIFIED' );
delta_ok( $e15->{equatorial}, 6377304.063 ); 
delta_ok( $e15->{polar}, 6356103.03899315 ); 
delta_ok( $e15->{flattening}, 0.00332444929666288 ); 
delta_ok( $e->{equatorial}, 6377304.063 ); 
delta_ok( $e->{polar}, 6356103.03899315 ); 
delta_ok( $e->{flattening}, 0.00332444929666288 ); 

my $e16 = Geo::Ellipsoid->new();
$e->set_ellipsoid('FISHER-1960');
$e16->set_ellipsoid('FISHER-1960');
ok( $e->{ellipsoid} eq 'FISHER-1960' );
ok( $e16->{ellipsoid} eq 'FISHER-1960' );
delta_ok( $e16->{equatorial}, 6378166 ); 
delta_ok( $e16->{polar}, 6356784.28360711 ); 
delta_ok( $e16->{flattening}, 0.00335232986925913 ); 
delta_ok( $e->{equatorial}, 6378166 ); 
delta_ok( $e->{polar}, 6356784.28360711 ); 
delta_ok( $e->{flattening}, 0.00335232986925913 ); 

my $e17 = Geo::Ellipsoid->new();
$e->set_ellipsoid('FISHER-1968');
$e17->set_ellipsoid('FISHER-1968');
ok( $e->{ellipsoid} eq 'FISHER-1968' );
ok( $e17->{ellipsoid} eq 'FISHER-1968' );
delta_ok( $e17->{equatorial}, 6378150 ); 
delta_ok( $e17->{polar}, 6356768.33724438 ); 
delta_ok( $e17->{flattening}, 0.00335232986925913 ); 
delta_ok( $e->{equatorial}, 6378150 ); 
delta_ok( $e->{polar}, 6356768.33724438 ); 
delta_ok( $e->{flattening}, 0.00335232986925913 ); 

my $e18 = Geo::Ellipsoid->new();
$e->set_ellipsoid('GRS80');
$e18->set_ellipsoid('GRS80');
ok( $e->{ellipsoid} eq 'GRS80' );
ok( $e18->{ellipsoid} eq 'GRS80' );
delta_ok( $e18->{equatorial}, 6378137 ); 
delta_ok( $e18->{polar}, 6356752.31414035 ); 
delta_ok( $e18->{flattening}, 0.00335281068118367 ); 
delta_ok( $e->{equatorial}, 6378137 ); 
delta_ok( $e->{polar}, 6356752.31414035 ); 
delta_ok( $e->{flattening}, 0.00335281068118367 ); 

my $e19 = Geo::Ellipsoid->new();
$e->set_ellipsoid('HAYFORD');
$e19->set_ellipsoid('HAYFORD');
ok( $e->{ellipsoid} eq 'HAYFORD' );
ok( $e19->{ellipsoid} eq 'HAYFORD' );
delta_ok( $e19->{equatorial}, 6378388 ); 
delta_ok( $e19->{polar}, 6356911.94612795 ); 
delta_ok( $e19->{flattening}, 0.00336700336700337 ); 
delta_ok( $e->{equatorial}, 6378388 ); 
delta_ok( $e->{polar}, 6356911.94612795 ); 
delta_ok( $e->{flattening}, 0.00336700336700337 ); 

my $e20 = Geo::Ellipsoid->new();
$e->set_ellipsoid('HOUGH-1956');
$e20->set_ellipsoid('HOUGH-1956');
ok( $e->{ellipsoid} eq 'HOUGH-1956' );
ok( $e20->{ellipsoid} eq 'HOUGH-1956' );
delta_ok( $e20->{equatorial}, 6378270 ); 
delta_ok( $e20->{polar}, 6356794.34343434 ); 
delta_ok( $e20->{flattening}, 0.00336700336700337 ); 
delta_ok( $e->{equatorial}, 6378270 ); 
delta_ok( $e->{polar}, 6356794.34343434 ); 
delta_ok( $e->{flattening}, 0.00336700336700337 ); 

my $e21 = Geo::Ellipsoid->new();
$e->set_ellipsoid('IAU76');
$e21->set_ellipsoid('IAU76');
ok( $e->{ellipsoid} eq 'IAU76' );
ok( $e21->{ellipsoid} eq 'IAU76' );
delta_ok( $e21->{equatorial}, 6378140 ); 
delta_ok( $e21->{polar}, 6356755.28815753 ); 
delta_ok( $e21->{flattening}, 0.00335281317789691 ); 
delta_ok( $e->{equatorial}, 6378140 ); 
delta_ok( $e->{polar}, 6356755.28815753 ); 
delta_ok( $e->{flattening}, 0.00335281317789691 ); 

my $e22 = Geo::Ellipsoid->new();
$e->set_ellipsoid('KRASSOVSKY-1938');
$e22->set_ellipsoid('KRASSOVSKY-1938');
ok( $e->{ellipsoid} eq 'KRASSOVSKY-1938' );
ok( $e22->{ellipsoid} eq 'KRASSOVSKY-1938' );
delta_ok( $e22->{equatorial}, 6378245 ); 
delta_ok( $e22->{polar}, 6356863.01877305 ); 
delta_ok( $e22->{flattening}, 0.00335232986925913 ); 
delta_ok( $e->{equatorial}, 6378245 ); 
delta_ok( $e->{polar}, 6356863.01877305 ); 
delta_ok( $e->{flattening}, 0.00335232986925913 ); 

my $e23 = Geo::Ellipsoid->new();
$e->set_ellipsoid('NAD27');
$e23->set_ellipsoid('NAD27');
ok( $e->{ellipsoid} eq 'NAD27' );
ok( $e23->{ellipsoid} eq 'NAD27' );
delta_ok( $e23->{equatorial}, 6378206.4 ); 
delta_ok( $e23->{polar}, 6356583.79999999 ); 
delta_ok( $e23->{flattening}, 0.00339007530392992 ); 
delta_ok( $e->{equatorial}, 6378206.4 ); 
delta_ok( $e->{polar}, 6356583.79999999 ); 
delta_ok( $e->{flattening}, 0.00339007530392992 ); 

my $e24 = Geo::Ellipsoid->new();
$e->set_ellipsoid('NWL-9D');
$e24->set_ellipsoid('NWL-9D');
ok( $e->{ellipsoid} eq 'NWL-9D' );
ok( $e24->{ellipsoid} eq 'NWL-9D' );
delta_ok( $e24->{equatorial}, 6378145 ); 
delta_ok( $e24->{polar}, 6356759.76948868 ); 
delta_ok( $e24->{flattening}, 0.00335289186923722 ); 
delta_ok( $e->{equatorial}, 6378145 ); 
delta_ok( $e->{polar}, 6356759.76948868 ); 
delta_ok( $e->{flattening}, 0.00335289186923722 ); 

my $e25 = Geo::Ellipsoid->new();
$e->set_ellipsoid('SOUTHAMERICAN-1969');
$e25->set_ellipsoid('SOUTHAMERICAN-1969');
ok( $e->{ellipsoid} eq 'SOUTHAMERICAN-1969' );
ok( $e25->{ellipsoid} eq 'SOUTHAMERICAN-1969' );
delta_ok( $e25->{equatorial}, 6378160 ); 
delta_ok( $e25->{polar}, 6356774.71919531 ); 
delta_ok( $e25->{flattening}, 0.00335289186923722 ); 
delta_ok( $e->{equatorial}, 6378160 ); 
delta_ok( $e->{polar}, 6356774.71919531 ); 
delta_ok( $e->{flattening}, 0.00335289186923722 ); 

my $e26 = Geo::Ellipsoid->new();
$e->set_ellipsoid('SOVIET-1985');
$e26->set_ellipsoid('SOVIET-1985');
ok( $e->{ellipsoid} eq 'SOVIET-1985' );
ok( $e26->{ellipsoid} eq 'SOVIET-1985' );
delta_ok( $e26->{equatorial}, 6378136 ); 
delta_ok( $e26->{polar}, 6356751.30156878 ); 
delta_ok( $e26->{flattening}, 0.00335281317789691 ); 
delta_ok( $e->{equatorial}, 6378136 ); 
delta_ok( $e->{polar}, 6356751.30156878 ); 
delta_ok( $e->{flattening}, 0.00335281317789691 ); 

my $e27 = Geo::Ellipsoid->new();
$e->set_ellipsoid('WGS72');
$e27->set_ellipsoid('WGS72');
ok( $e->{ellipsoid} eq 'WGS72' );
ok( $e27->{ellipsoid} eq 'WGS72' );
delta_ok( $e27->{equatorial}, 6378135 ); 
delta_ok( $e27->{polar}, 6356750.52001609 ); 
delta_ok( $e27->{flattening}, 0.0033527794541675 ); 
delta_ok( $e->{equatorial}, 6378135 ); 
delta_ok( $e->{polar}, 6356750.52001609 ); 
delta_ok( $e->{flattening}, 0.0033527794541675 ); 

my $e28 = Geo::Ellipsoid->new();
$e->set_ellipsoid('WGS84');
$e28->set_ellipsoid('WGS84');
ok( $e->{ellipsoid} eq 'WGS84' );
ok( $e28->{ellipsoid} eq 'WGS84' );
delta_ok( $e28->{equatorial}, 6378137 ); 
delta_ok( $e28->{polar}, 6356752.31424518 ); 
delta_ok( $e28->{flattening}, 0.00335281066474748 ); 
delta_ok( $e->{equatorial}, 6378137 ); 
delta_ok( $e->{polar}, 6356752.31424518 ); 
delta_ok( $e->{flattening}, 0.00335281066474748 ); 

