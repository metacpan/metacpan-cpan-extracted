package Google::Directions::Response::Polyline;
use Moose;
use Google::Directions::Types 'ArrayRefOfPoints';
use Google::Directions::Response::Coordinates;
use Moose::Util::TypeConstraints;
use Algorithm::GooglePolylineEncoding;

=head1 NAME

Google::Directions::Response::Polyline - sequence of points making a polyline

=head1 SYNOPSIS

    my $poly = $route->overview_polyline();
    foreach( @{ $poly->points } ){
        # Do something with the coordinates...
    }

=cut

subtype ArrayRefOfPoints,
    as 'ArrayRef';

coerce ArrayRefOfPoints,
    from 'Str',
    via { _decode_points( $_ ) };


=head1 ATTRIBUTES

=over 4

=item I<points> ArrayRef of L<Google::Directions::Response::Coordinates>

=back

=cut

has 'points' => ( is => 'ro', isa => ArrayRefOfPoints, coerce => 1 );

sub _decode_points{
  my $quintets = shift;
  my @coordinates = ();
  my @coords;
  
  @coords = Algorithm::GooglePolylineEncoding::decode_polyline($quintets);
  my $ccnt = 0;
  foreach my $pt(@coords){
      push( @coordinates, Google::Directions::Response::Coordinates->new(
            lat => $pt->{lat},
            lng => $pt->{lon},
            ) );
  }
 return \@coordinates;  

}


1;

=head1 AUTHOR

Robin Clarke, C<< <perl at robinclarke.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Robin Clarke.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
