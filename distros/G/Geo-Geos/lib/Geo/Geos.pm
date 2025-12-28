package Geo::Geos;
use 5.012;
use Export::XS();

our $VERSION = '1.0.8';

require XS::Loader;
XS::Loader::load();

1;
