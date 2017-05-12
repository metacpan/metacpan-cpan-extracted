package Geo::Routing::Driver::OSRM::Route;
BEGIN {
  $Geo::Routing::Driver::OSRM::Route::AUTHORITY = 'cpan:AVAR';
}
BEGIN {
  $Geo::Routing::Driver::OSRM::Route::VERSION = '0.11';
}
use Any::Moose;
use warnings FATAL => "all";

with 'Geo::Routing::Role::Route';

sub _build_travel_time { die "This should already be set implicitly" }

1;
