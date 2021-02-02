package GIS::Distance;
use 5.008001;
use strictures 2;
our $VERSION = '0.19';

sub new {
    my ($class, $formula, @args) = @_;

    $formula ||= 'Haversine';

    my @modules;
    push @modules, "GIS::Distance::Fast::${formula}"
        unless $ENV{GIS_DISTANCE_PP} or $ENV{GEO_DISTANCE_PP};
    push @modules, "GIS::Distance::$formula";
    push @modules, $formula;

    foreach my $module (@modules) {
        next if !_try_load_module( $module );
        next if !$module->isa('GIS::Distance::Formula');

        return $module->new( @args );
    }

    die "Cannot find a GIS::Distance::Formula class for $formula";
};

my %tried_modules;

sub _try_load_module {
    my ($module) = @_;

    return $tried_modules{ $module }
        if defined $tried_modules{ $module };

    $tried_modules{ $module } = 1;
    my $ok = eval( "require $module; 1" );
    return 1 if $ok;

    $tried_modules{ $module } = 0;
    die $@ if $@ !~ m{^Can't locate};
    return 0;
}

1;
__END__

=encoding utf8

=head1 NAME

GIS::Distance - Calculate geographic distances.

=head1 SYNOPSIS

    use GIS::Distance;
    
    # Use the GIS::Distance::Haversine formula by default.
    my $gis = GIS::Distance->new();
    
    # Or choose a different formula.
    my $gis = GIS::Distance->new( 'Polar' );
    
    # Returns a Class::Measure object.
    my $distance = $gis->distance( $lat1, $lon1, $lat2, $lon2 );
    
    print $distance->meters();

=head1 DESCRIPTION

This module calculates distances between geographic points on, at the moment,
planet Earth.  Various L</FORMULAS> are available that provide different levels
of accuracy versus speed.

L<GIS::Distance::Fast>, a separate distribution, ships with C implmentations of
some of the formulas shipped with GIS::Distance.  If you're looking for speed
then install it and the ::Fast formulas will be automatically used by this module.

=head1 METHODS

=head2 distance

    my $distance = $gis->distance( $lat1, $lon1, $lat2, $lon2 );
    
    my $point1 = Geo::Point->latlong( $lat1, $lon1 );
    my $point2 = Geo::Point->latlong( $lat2, $lon2 );
    my $distance = $gis->distance( $point1, $point2 );

Takes either two decimal latitude and longitude pairs, or two L<Geo::Point>
objects.

Returns a L<Class::Measure::Length> object for the distance between the
two degree lats/lons.

See L</distance_metal> for a faster, but less feature rich, method.

=head2 distance_metal

This works just like L</distance> except for:

=over

=item *

Does not accept L<Geo::Point> objects.  Only decimal latitude and longitude
pairs.

=item *

Does not return a L<Class::Measure> object.  Instead kilometers are always
returned.

=item *

Does no argument checking.

=item *

Does not support formula arguments which are supported by at least the
L<GIS::Distance::GeoEllipsoid> formula.

=back

Calling this gets you pretty close to the fastest bare metal speed you can get.
The speed improvements of calling this is noticeable over hundreds of thousands of
iterations only and you've got to decide if its worth the safety and features
you are dropping.  Read more in the L</SPEED> section.

=head1 ARGUMENTS

    my $gis = GIS::Distance->new( $formula );

When you call C<new()> you may pass a partial or full formula class name as the
first argument.  The default is C<Haversive>.

If you pass a partial name, as in:

    my $gis = GIS::Distance->new( 'Haversine' );

Then the following modules will be looked for in order:

    GIS::Distance::Fast::Haversine
    GIS::Distance::Haversine
    Haversine

Install L<GIS::Distance::Fast> to get access to the C<Fast::> (XS) implementations
of the formula classes.

You may globally disable the automatic use of the C<Fast::> formulas by setting
the C<GIS_DISTANCE_PP> environment variable.  Although, its likely simpler to
just provide a full class name to get the same effect:

    my $gis = GIS::Distance->new( 'GIS::Distance::Haversine' );

=head1 SPEED

Not that this module is slow, but if you're doing millions of distance
calculations a second you may find that adjusting your code a bit may
make it faster.  Here are some options.

Install L<GIS::Distance::Fast> to get the XS variants for most of the
PP formulas.

Use L</distance_metal> instead of L</distance>.

Call the undocumented C<_distance()> function that each formula class
has.  For example you could bypass this module entirely and just do:

    use GIS::Distance::Fast::Haversine;
    my $km = GIS::Distance::Fast::Haversine::_distance( @coords );

The above would be the ultimate speed demon (as shown in benchmarking)
but throws away some flexibility and adds some foot-gun support.

Here's a benchmarks for these options:

    2019-03-13T09:34:00Z
    GIS::Distance 0.15
    GIS::Distance::Fast 0.12
    GIS::Distance::Fast::Haversine 0.12
    GIS::Distance::Haversine 0.15
                                                                 Rate
    PP Haversine - GIS::Distance->distance                   123213/s
    XS Haversine - GIS::Distance->distance                   196232/s
    PP Haversine - GIS::Distance->distance_metal             356379/s
    PP Haversine - GIS::Distance::Haversine::_distance       385208/s
    XS Haversine - GIS::Distance->distance_metal             3205128/s
    XS Haversine - GIS::Distance::Fast::Haversine::_distance 8620690/s

You can run your own benchmarks using the included C<author/bench>
script.  The above results were produced with:

    author/bench -f Haversine

The slowest result was about C<125000/s>, or about C<8ms> each call.
This could be a substantial burden in some contexts, such as live HTTP
responses to human users and running large batch jobs, to name just two.

In conclusion, if you can justify the speed gain, switching to
L</distance_metal> and installing L<GIS::Distance::Fast> looks to be an
ideal setup.

As always with performance and benchmarking, YMMV.

=head1 COORDINATES

When passing latitudinal and longitudinal coordinates to L</distance>
they must always be in decimal degree format.  Here is some sample code
for converting from other formats to decimal:

    # DMS to Decimal
    my $decimal = $degrees + ($minutes/60) + ($seconds/3600);
    
    # Precision Six Integer to Decimal
    my $decimal = $integer * .000001;

If you want to convert from decimal radians to degrees you can use L<Math::Trig>'s
rad2deg function.

=head1 FORMULAS

These formulas come bundled with this distribution:

=over

=item *

L<GIS::Distance::ALT>

=item *

L<GIS::Distance::Cosine>

=item *

L<GIS::Distance::GreatCircle>

=item *

L<GIS::Distance::Haversine>

=item *

L<GIS::Distance::MathTrig>

=item *

L<GIS::Distance::Null>

=item *

L<GIS::Distance::Polar>

=item *

L<GIS::Distance::Vincenty>

=back

These formulas are available on CPAN:

=over

=item *

L<GIS::Distance::Fast/FORMULAS>

=item *

L<GIS::Distance::GeoEllipsoid>

=back

=head1 AUTHORING

Take a look at L<GIS::Distance::Formula> for instructions on authoring
new formula classes.

=head1 SEE ALSO

=over

=item *

L<Geo::Distance> - Is deprecated in favor of using this module.

=item *

L<Geo::Distance::Google> - While in the Geo::Distance namespace, this isn't
actually related to Geo::Distance at all.  Might be useful though.

=item *

L<GIS::Distance::Lite> - An old fork of this module, not recommended.

=item *

L<Geo::Distance::XS> - Used to be used by L<Geo::Distance> but no longer is.

=item *

L<Geo::Ellipsoid> - Or use L<GIS::Distance::GeoEllipsoid> for a uniform
interface.

=item *

L<Geo::Inverse> - Does some distance calculations, but seems less than useful
as all the code looks to be taken from L<Geo::Ellipsoid>.

=back

=head1 SUPPORT

Please submit bugs and feature requests to the
GIS-Distance GitHub issue tracker:

L<https://github.com/bluefeet/GIS-Distance/issues>

=head1 AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>
    Mohammad S Anwar <mohammad.anwar@yahoo.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

