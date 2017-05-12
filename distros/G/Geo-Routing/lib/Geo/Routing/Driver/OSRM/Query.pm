package Geo::Routing::Driver::OSRM::Query;
BEGIN {
  $Geo::Routing::Driver::OSRM::Query::AUTHORITY = 'cpan:AVAR';
}
BEGIN {
  $Geo::Routing::Driver::OSRM::Query::VERSION = '0.11';
}
use Any::Moose;
use warnings FATAL => "all";

with 'Geo::Routing::Role::Query';

sub query_string {
    my ($self, $method) = @_;
    $method ||= "json";

    my @atoms = qw(from_latitude from_longitude to_latitude to_longitude);

    my $query_string = "&output=$method&instructions=true&geometry=false&" . join '&', map { $self->$_ } @atoms;

    return $query_string;
}

1;
