package GIS::Distance;
$GIS::Distance::VERSION = '0.09';
=head1 NAME

GIS::Distance - Calculate geographic distances.

=head1 SYNOPSIS

    use GIS::Distance;
    
    my $gis = GIS::Distance->new();
    $gis->formula( 'Polar' );  # Optional, default is Haversine.
    
    # Or:
    my $gis = GIS::Distance->new( 'Polar' );
    
    my $distance = $gis->distance( $lat1,$lon1 => $lat2,$lon2 );
    
    print $distance->meters();

=head1 DESCRIPTION

This module calculates distances between geographic points on, at the moment,
plant Earth.  Various formulas are available that provide different levels of
accuracy versus calculation speed tradeoffs.

All distances are returned as L<Class::Measure> objects.

=cut

use Types::Standard -types;
use Type::Utils -all;

use Moo;
use strictures 1;
use namespace::clean;

around BUILDARGS => sub{
    my $orig = shift;
    my $class = shift;

    if (@_==1 and ref($_[0]) ne 'HASH') {
        return { formula => $_[0] };
    }

    return $class->$orig( @_ );
};

=head1 METHODS

=head2 distance

  my $distance = $gis->distance( $lat1,$lon1 => $lat2,$lon2 );

Returns a L<Class::Measure::Length> object for the distance between the
two degree lats/lons.  The distance is calculated using whatever formula
the object is set to use.

=head1 ATTRIBUTES

=head2 formula

This is an object who's class inherits from L<GIS::Distance::Formula>.  This
object is used to calculate distance.  The formula may be specified as either
a blessed object, or as a string, such as "Haversine" or any of the other formulas.

If you specify the formula as a string then a few different class names will be
searched for.  So, if you did:

  $gis->formula( 'Haversine' );

Then this list of packages would automatically be looked for.  The first one that
exists will be created and used:

  GIS::Distance::Formula::Haversine::Fast
  GIS::Distance::Formula::Haversine
  Haversine

If you are using your own custom formula class make sure it applies
the L<GIS::Distance::Formula> role.

Note that a ::Fast version of the class will be looked for first.  By default
the ::Fast versions of the formulas, written in C, are not available and the
pure perl ones will be used instead.  If you would like the ::Fast formulas
then install L<GIS::Distance::Fast> and they will be automatically used.

=cut

my $formula_type = declare 'GISDistanceFormula',
    as HasMethods[ 'distance' ];

coerce $formula_type,
    from Str,
    via {
        my $class = $_;
        foreach my $full_class (
            "GIS::Distance::Formula::${class}::Fast",
            "GIS::Distance::Formula::$class",
            $class,
        ) {
            local $@;
            my $success = eval( "require $full_class; 1" );
            return $full_class->new() if $success;
            die $@ if $@ !~ m{^Can't locate};
        }
        die( qq{The GIS::Distance formula "$class" cannot be found} );
    };

has formula => (
    is      => 'rw',
    isa     => $formula_type,
    coerce  => 1,
    default => 'Haversine',
    handles => ['distance'],
);

1;
__END__

=head1 SEE ALSO

L<GIS::Distance::Fast> - C implmentation of some of the formulas
shipped with GIS::Distance.  This greatly increases the speed at
which distance calculations can be made.

=head1 FORMULAS

L<GIS::Distance::Formula::Cosine>

L<GIS::Distance::Formula::GeoEllipsoid>

L<GIS::Distance::Formula::GreatCircle>

L<GIS::Distance::Formula::Haversine>

L<GIS::Distance::Formula::MathTrig>

L<GIS::Distance::Formula::Polar>

L<GIS::Distance::Formula::Vincenty>

=head1 TODO

=over 4

=item *

Create a GIS::Coord class that represents a geographic coordinate.  Then modify
this module to accept input as either lat/lon pairs, or as GIS::Coord objects.

=item *

Create an extension to DBIx::Class with the same goal as L<Geo::Distance>'s
closest() method.

=item *

Write a super accurate formula module called GIS::Distance::Geoid.  Some
very useful info is at L<http://en.wikipedia.org/wiki/Geoid>.

=back

=head1 BUGS

Both the L<GIS::Distance::Formula::GreatCircle> and L<GIS::Distance::Formula::Polar> formulas are
broken.  Read their respective man pages for details.

=head1 AUTHOR

Aran Clary Deltac <bluefeet@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

