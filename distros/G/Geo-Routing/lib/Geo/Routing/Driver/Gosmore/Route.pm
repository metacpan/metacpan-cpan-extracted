package Geo::Routing::Driver::Gosmore::Route;
BEGIN {
  $Geo::Routing::Driver::Gosmore::Route::AUTHORITY = 'cpan:AVAR';
}
BEGIN {
  $Geo::Routing::Driver::Gosmore::Route::VERSION = '0.11';
}
use Any::Moose;
use warnings FATAL => "all";

with 'Geo::Routing::Role::Route';

sub _build_travel_time {
    my ($self) = @_;

    my $first_point = $self->points->[0];
    my $travel_time = $first_point->[4];

    return $travel_time;
}

1;
