#!/usr/local/bin/perl
# Test Geo::Ellipsoid defaults
use Test::More tests => 192;
use Test::Number::Delta relative => 1e-6;
use Geo::Ellipsoid;
use blib;
use strict;
use warnings;

my $e1 = Geo::Ellipsoid->new();
ok( $e1->{ellipsoid} eq 'WGS84' );
ok( $e1->{units} eq 'radians' );
ok( $e1->{distance_units} eq 'meter' );
ok( $e1->{longitude} == 0 );
ok( $e1->{latitude} == 1 );
ok( $e1->{bearing} == 0 );
$e1->set_defaults( 
  ellipsoid => 'NAD27',
  units => 'degrees', 
  distance_units => 'kilometer',
  longitude => 1,
  bearing => 1
);
my $e2 = Geo::Ellipsoid->new();
ok( $e2->{ellipsoid} eq 'NAD27' );
ok( $e2->{units} eq 'degrees' );
ok( $e2->{distance_units} eq 'kilometer' );
ok( $e2->{longitude} == 1 );
ok( $e2->{latitude} == 1 );
ok( $e2->{bearing} == 1 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'EVEREST-1830');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'EVEREST-1830' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e3 = Geo::Ellipsoid->new();
ok( defined $e3 );
ok( $e3->isa( 'Geo::Ellipsoid' ) );
ok( $e3->{ellipsoid} eq 'EVEREST-1830' );
ok( $e3->{units} eq 'degrees' );
delta_ok( $e3->{equatorial}, 6377276.345 );
delta_ok( $e3->{polar}, 6356075.41314024 );
delta_ok( $e3->{flattening}, 0.00332444929666288 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'HOUGH-1956');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'HOUGH-1956' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e4 = Geo::Ellipsoid->new();
ok( defined $e4 );
ok( $e4->isa( 'Geo::Ellipsoid' ) );
ok( $e4->{ellipsoid} eq 'HOUGH-1956' );
ok( $e4->{units} eq 'degrees' );
delta_ok( $e4->{equatorial}, 6378270 );
delta_ok( $e4->{polar}, 6356794.34343434 );
delta_ok( $e4->{flattening}, 0.00336700336700337 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'HAYFORD');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'HAYFORD' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e5 = Geo::Ellipsoid->new();
ok( defined $e5 );
ok( $e5->isa( 'Geo::Ellipsoid' ) );
ok( $e5->{ellipsoid} eq 'HAYFORD' );
ok( $e5->{units} eq 'degrees' );
delta_ok( $e5->{equatorial}, 6378388 );
delta_ok( $e5->{polar}, 6356911.94612795 );
delta_ok( $e5->{flattening}, 0.00336700336700337 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'AIRY-MODIFIED');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'AIRY-MODIFIED' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e6 = Geo::Ellipsoid->new();
ok( defined $e6 );
ok( $e6->isa( 'Geo::Ellipsoid' ) );
ok( $e6->{ellipsoid} eq 'AIRY-MODIFIED' );
ok( $e6->{units} eq 'degrees' );
delta_ok( $e6->{equatorial}, 6377340.189 );
delta_ok( $e6->{polar}, 6356034.44793853 );
delta_ok( $e6->{flattening}, 0.00334085064149708 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'NWL-9D');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'NWL-9D' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e7 = Geo::Ellipsoid->new();
ok( defined $e7 );
ok( $e7->isa( 'Geo::Ellipsoid' ) );
ok( $e7->{ellipsoid} eq 'NWL-9D' );
ok( $e7->{units} eq 'degrees' );
delta_ok( $e7->{equatorial}, 6378145 );
delta_ok( $e7->{polar}, 6356759.76948868 );
delta_ok( $e7->{flattening}, 0.00335289186923722 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'CLARKE-1880');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'CLARKE-1880' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e8 = Geo::Ellipsoid->new();
ok( defined $e8 );
ok( $e8->isa( 'Geo::Ellipsoid' ) );
ok( $e8->{ellipsoid} eq 'CLARKE-1880' );
ok( $e8->{units} eq 'degrees' );
delta_ok( $e8->{equatorial}, 6378249.145 );
delta_ok( $e8->{polar}, 6356514.86954978 );
delta_ok( $e8->{flattening}, 0.00340756137869933 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'KRASSOVSKY-1938');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'KRASSOVSKY-1938' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e9 = Geo::Ellipsoid->new();
ok( defined $e9 );
ok( $e9->isa( 'Geo::Ellipsoid' ) );
ok( $e9->{ellipsoid} eq 'KRASSOVSKY-1938' );
ok( $e9->{units} eq 'degrees' );
delta_ok( $e9->{equatorial}, 6378245 );
delta_ok( $e9->{polar}, 6356863.01877305 );
delta_ok( $e9->{flattening}, 0.00335232986925913 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'FISHER-1968');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'FISHER-1968' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e10 = Geo::Ellipsoid->new();
ok( defined $e10 );
ok( $e10->isa( 'Geo::Ellipsoid' ) );
ok( $e10->{ellipsoid} eq 'FISHER-1968' );
ok( $e10->{units} eq 'degrees' );
delta_ok( $e10->{equatorial}, 6378150 );
delta_ok( $e10->{polar}, 6356768.33724438 );
delta_ok( $e10->{flattening}, 0.00335232986925913 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'AUSTRALIAN');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'AUSTRALIAN' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e11 = Geo::Ellipsoid->new();
ok( defined $e11 );
ok( $e11->isa( 'Geo::Ellipsoid' ) );
ok( $e11->{ellipsoid} eq 'AUSTRALIAN' );
ok( $e11->{units} eq 'degrees' );
delta_ok( $e11->{equatorial}, 6378160 );
delta_ok( $e11->{polar}, 6356774.71919531 );
delta_ok( $e11->{flattening}, 0.00335289186923722 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'EVEREST-MODIFIED');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'EVEREST-MODIFIED' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e12 = Geo::Ellipsoid->new();
ok( defined $e12 );
ok( $e12->isa( 'Geo::Ellipsoid' ) );
ok( $e12->{ellipsoid} eq 'EVEREST-MODIFIED' );
ok( $e12->{units} eq 'degrees' );
delta_ok( $e12->{equatorial}, 6377304.063 );
delta_ok( $e12->{polar}, 6356103.03899315 );
delta_ok( $e12->{flattening}, 0.00332444929666288 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'WGS72');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'WGS72' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e13 = Geo::Ellipsoid->new();
ok( defined $e13 );
ok( $e13->isa( 'Geo::Ellipsoid' ) );
ok( $e13->{ellipsoid} eq 'WGS72' );
ok( $e13->{units} eq 'degrees' );
delta_ok( $e13->{equatorial}, 6378135 );
delta_ok( $e13->{polar}, 6356750.52001609 );
delta_ok( $e13->{flattening}, 0.0033527794541675 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'FISHER-1960');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'FISHER-1960' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e14 = Geo::Ellipsoid->new();
ok( defined $e14 );
ok( $e14->isa( 'Geo::Ellipsoid' ) );
ok( $e14->{ellipsoid} eq 'FISHER-1960' );
ok( $e14->{units} eq 'degrees' );
delta_ok( $e14->{equatorial}, 6378166 );
delta_ok( $e14->{polar}, 6356784.28360711 );
delta_ok( $e14->{flattening}, 0.00335232986925913 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'BESSEL-1841');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'BESSEL-1841' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e15 = Geo::Ellipsoid->new();
ok( defined $e15 );
ok( $e15->isa( 'Geo::Ellipsoid' ) );
ok( $e15->{ellipsoid} eq 'BESSEL-1841' );
ok( $e15->{units} eq 'degrees' );
delta_ok( $e15->{equatorial}, 6377397.155 );
delta_ok( $e15->{polar}, 6356078.96281819 );
delta_ok( $e15->{flattening}, 0.00334277318217481 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'AIRY');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'AIRY' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e16 = Geo::Ellipsoid->new();
ok( defined $e16 );
ok( $e16->isa( 'Geo::Ellipsoid' ) );
ok( $e16->{ellipsoid} eq 'AIRY' );
ok( $e16->{units} eq 'degrees' );
delta_ok( $e16->{equatorial}, 6377563.396 );
delta_ok( $e16->{polar}, 6356256.90923729 );
delta_ok( $e16->{flattening}, 0.00334085064149708 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'GRS80');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'GRS80' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e17 = Geo::Ellipsoid->new();
ok( defined $e17 );
ok( $e17->isa( 'Geo::Ellipsoid' ) );
ok( $e17->{ellipsoid} eq 'GRS80' );
ok( $e17->{units} eq 'degrees' );
delta_ok( $e17->{equatorial}, 6378137 );
delta_ok( $e17->{polar}, 6356752.31414035 );
delta_ok( $e17->{flattening}, 0.00335281068118367 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'IAU76');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'IAU76' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e18 = Geo::Ellipsoid->new();
ok( defined $e18 );
ok( $e18->isa( 'Geo::Ellipsoid' ) );
ok( $e18->{ellipsoid} eq 'IAU76' );
ok( $e18->{units} eq 'degrees' );
delta_ok( $e18->{equatorial}, 6378140 );
delta_ok( $e18->{polar}, 6356755.28815753 );
delta_ok( $e18->{flattening}, 0.00335281317789691 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'SOUTHAMERICAN-1969');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'SOUTHAMERICAN-1969' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e19 = Geo::Ellipsoid->new();
ok( defined $e19 );
ok( $e19->isa( 'Geo::Ellipsoid' ) );
ok( $e19->{ellipsoid} eq 'SOUTHAMERICAN-1969' );
ok( $e19->{units} eq 'degrees' );
delta_ok( $e19->{equatorial}, 6378160 );
delta_ok( $e19->{polar}, 6356774.71919531 );
delta_ok( $e19->{flattening}, 0.00335289186923722 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'WGS84');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'WGS84' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e20 = Geo::Ellipsoid->new();
ok( defined $e20 );
ok( $e20->isa( 'Geo::Ellipsoid' ) );
ok( $e20->{ellipsoid} eq 'WGS84' );
ok( $e20->{units} eq 'degrees' );
delta_ok( $e20->{equatorial}, 6378137 );
delta_ok( $e20->{polar}, 6356752.31424518 );
delta_ok( $e20->{flattening}, 0.00335281066474748 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'SOVIET-1985');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'SOVIET-1985' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e21 = Geo::Ellipsoid->new();
ok( defined $e21 );
ok( $e21->isa( 'Geo::Ellipsoid' ) );
ok( $e21->{ellipsoid} eq 'SOVIET-1985' );
ok( $e21->{units} eq 'degrees' );
delta_ok( $e21->{equatorial}, 6378136 );
delta_ok( $e21->{polar}, 6356751.30156878 );
delta_ok( $e21->{flattening}, 0.00335281317789691 );

Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'NAD27');
ok( $Geo::Ellipsoid::defaults{ellipsoid} eq 'NAD27' );
ok( $Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $e22 = Geo::Ellipsoid->new();
ok( defined $e22 );
ok( $e22->isa( 'Geo::Ellipsoid' ) );
ok( $e22->{ellipsoid} eq 'NAD27' );
ok( $e22->{units} eq 'degrees' );
delta_ok( $e22->{equatorial}, 6378206.4 );
delta_ok( $e22->{polar}, 6356583.79999999 );
delta_ok( $e22->{flattening}, 0.00339007530392992 );

