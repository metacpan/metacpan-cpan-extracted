package GIS::Distance;
use 5.008001;
use strictures 2;
our $VERSION = '0.10';

use Class::Measure::Length qw( length );
use Carp qw( croak );
use namespace::clean;

sub new {
    my ($class, $formula, @args) = @_;

    $formula ||= 'Haversine';

    my $self = bless {
        formula => $formula,
        args    => \@args,
    }, $class;

    foreach my $module (
        "GIS::Distance::Fast::${formula}",
        "GIS::Distance::$formula",

        # Continue supporting the older package names:
        "GIS::Distance::Formula::${formula}::Fast",
        "GIS::Distance::Formula::$formula",

        # Support custom formula classes:
        $formula,
    ) {
        my $code = $module->can('distance');

        if (!$code) {
            local $@;
            my $loaded_ok = eval( "require $module; 1" );

            if (!$loaded_ok) {
                die $@ if $@ !~ m{^Can't locate};
                next;
            }

            $code = $module->can('distance');
            die "$module does not have a distance() function" if !$code;
        }

        $self->{module} = $module;
        $self->{code} = $code;
        last;
    }

    die "Cannot find a GIS::Distance formula module for $formula"
        if !$self->{code};

    return $self;
};

sub formula { $_[0]->{formula} }
sub args { $_[0]->{args} }
sub module { $_[0]->{module} }

sub distance {
    my $self = shift;

    croak 'Four arguments must be passed to distance()' if @_!=4;

    return length( $self->distance_km(@_), 'km' );
}

sub distance_km {
    my $self = shift;

    croak 'Four arguments must be passed to distance_km()' if @_!=4;

    return $self->{code}->( @_, @{$self->{args}} );
}

1;
__END__

=encoding utf8

=head1 NAME

GIS::Distance - Calculate geographic distances.

=head1 SYNOPSIS

    use GIS::Distance;
    
    # Use the GIS::Distance::Haversine formula by default:
    my $gis = GIS::Distance->new();
    
    # Or choose a different formula:
    my $gis = GIS::Distance->new( 'Polar' );
    
    my $distance = $gis->distance( $lat1,$lon1 => $lat2,$lon2 );
    
    print $distance->meters();

=head1 DESCRIPTION

This module calculates distances between geographic points on, at the moment,
plant Earth.  Various formulas are available that provide different levels of
accuracy versus calculation speed tradeoffs.

=head1 METHODS

=head2 distance

    my $distance = $gis->distance( $lat1,$lon1 => $lat2,$lon2 );

Returns a L<Class::Measure::Length> object for the distance between the
two degree lats/lons.

See L</distance_km> to return raw kilometers instead.

=head2 distance_km

This works just like L</distance> but return a raw kilometer measurement.

=head1 ATTRIBUTES

=head2 formula

Returns the formula name which was passed as the first argument to C<new()>.

The formula can be specified as a partial or full module name for that
formula.  For example, if the formula is set to C<Haversine> as in:

    my $gis = GIS::Distance->new( 'Haversine' );

Then the following modules will be looked for in order:

    GIS::Distance::Fast::Haversine
    GIS::Distance::Haversine
    Haversine

Note that a C<Fast::> version of the class will be looked for first.  By default
the C<Fast::> versions of the formulas, written in C, are not available and the
pure perl ones will be used instead.  If you would like the C<Fast::> formulas
then install L<GIS::Distance::Fast> and they will be automatically used.

=head2 args

Returns the formula arguments, an array ref, containing the rest of the
arguments passed to C<new()>.  Most formulas do not take arguments.  If
they do it will be described in their respective documentation.

=head2 module

Returns the fully qualified module name that L</formula> resolved to.

=head1 SEE ALSO

L<GIS::Distance::Fast> - C implmentation of some of the formulas
shipped with GIS::Distance.  This greatly increases the speed at
which distance calculations can be made.

=head1 FORMULAS

L<GIS::Distance::Cosine>

L<GIS::Distance::GeoEllipsoid>

L<GIS::Distance::GreatCircle>

L<GIS::Distance::Haversine>

L<GIS::Distance::MathTrig>

L<GIS::Distance::Polar>

L<GIS::Distance::Vincenty>

=head1 TODO

=over 4

=item *

Create a GIS::Coord class that represents a geographic coordinate.  Then modify
this module to accept input as either lat/lon pairs, or as GIS::Coord objects.

=item *

Create some sort of equivalent to L<Geo::Distance>'s closest() method.

=item *

Write a formula module called GIS::Distance::Geoid.  Some very useful info is
at L<http://en.wikipedia.org/wiki/Geoid>.

=back

=head1 BUGS

See L<GIS::Distance::Polar/BROKEN>.

=head1 SUPPORT

Please submit bugs and feature requests to the GIS-Distance GitHub issue tracker:

L<https://github.com/bluefeet/GIS-Distance/issues>

=head1 AUTHORS

    Aran Clary Deltac <bluefeet@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

