package Geo::Geos;
use 5.012;
use Export::XS();

our $VERSION = '1.0.6';

require XS::Loader;
XS::Loader::load();

1;
