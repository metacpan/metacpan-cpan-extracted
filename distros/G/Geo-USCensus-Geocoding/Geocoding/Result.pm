package Geo::USCensus::Geocoding::Result;

use Moo; # just for attribute declaration

has 'is_match' => ( is => 'rw', default => 0 );
foreach ( 'content',
          'match_level',
          'address',
          'state',
          'county',
          'tract',
          'block',
          'error_message',
          'latitude',
          'longitude'
        ) {
  has $_ => ( is => 'rw', default => '' );
}

sub censustract {
  my $self = shift;
  return join('', $self->state, $self->county, $self->tract);
}

1;
