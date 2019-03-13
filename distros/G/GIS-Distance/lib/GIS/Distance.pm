package GIS::Distance;
use 5.008001;
use strictures 2;
our $VERSION = '0.15';

use Class::Measure::Length qw( length );
use Carp qw( croak );
use Scalar::Util qw( blessed );
use namespace::clean;

sub new {
    my ($class, $formula, @args) = @_;

    $formula ||= 'Haversine';

    my $self = bless {
        formula => $formula,
        args    => \@args,
    }, $class;

    my @modules;
    push @modules, "GIS::Distance::Fast::${formula}"
        unless $ENV{GIS_DISTANCE_PP} or $ENV{GEO_DISTANCE_PP};
    push @modules, "GIS::Distance::$formula";
    push @modules, $formula;

    foreach my $module (@modules) {
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

    my @coords;
    foreach my $coord (@_) {
        if ((blessed($coord)||'') eq 'Geo::Point') {
            push @coords, $coord->latlong();
            next;
        }

        push @coords, $coord;
    }

    croak 'Invalid arguments passsed to distance()'
        if @coords!=4;

    return length(
        $self->{code}->( @coords, @{$self->{args}} ),
        'km',
    );
}

sub distance_metal {
    my $self = shift;
    return $self->{code}->( @_ );
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

Does not support formula L</args>, which are needed by at least the
L<GIS::Distance::GeoEllipsoid> formula.

=back

Calling this gets you pretty close to the fastest bare metal speed you can get.
The speed improvements of calling this is noticeable over millions of iterations
only and you've got to decide if its worth the safety and features you are dropping.

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

You may disable the automatic use of the C<Fast::> formulas by setting the
C<GIS_DISTANCE_PP> environment variable.

=head2 args

Returns the formula arguments, an array ref, containing the rest of the
arguments passed to C<new()> (anything passed after the L</formula>).
Most formulas do not take arguments.  If they do it will be described in
their respective documentation.

=head2 module

Returns the fully qualified module name that L</formula> resolved to.

=head1 SPEED

Not that this module is slow, but if you're doing millions of distance
calculations a second you may find that adjusting your code a bit may
make it faster.  Here are some options.

Install L<GIS::Distance::Fast> to get the XS variants for most of the
PP formulas.

Use L</distance_metal> instead of L</distance>.

Call the undocumented C<distance()> function that each formula module
has.  For example you could bypass this module entirely and just do:

    use GIS::Distance::Fast::Haversine;
    my $km = GIS::Distance::Fast::Haversine::distance( @coords );

The above would be the ultimate speed demon (as shown in benchmarking)
but throws away some flexibility and adds some foot-gun support.

Here's some benchmarks for these options:

    PP Haversine - GIS::Distance->distance                   125913/s
    XS Haversine - GIS::Distance->distance                   203335/s
    PP Haversine - GIS::Distance->distance_metal             366569/s
    PP Haversine - GIS::Distance::Haversine::distance        390320/s
    XS Haversine - GIS::Distance->distance_metal            3289474/s
    XS Haversine - GIS::Distance::Fast::Haversine::distance 8064516/s

You can run your own benchmarks using the included C<author/bench>
script.  The above results were produced with:

    author/bench -f Haversine

Even the slowest result was C<125913/s>, which is C<125.913/ms>, which
means each call took about C<0.0079ms>.

In conclusion, if you can justify the speed gain, switching to
L</distance_metal> and installing L<GIS::Distance::Fast>, seems
the ideal setup.

As always, YMMV.

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

These formulas come with this distribution:

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

L<GIS::Distance::Fast::ALT>

=item *

L<GIS::Distance::Fast::Cosine>

=item *

L<GIS::Distance::Fast::GreatCircle>

=item *

L<GIS::Distance::Fast::Haversine>

=item *

L<GIS::Distance::Fast::Polar>

=item *

L<GIS::Distance::Fast::Vincenty>

=item *

L<GIS::Distance::GeoEllipsoid>

=back

=head1 SEE ALSO

=over

=item *

L<Geo::Distance> - Is deprecated in favor of using this module.

=item *

L<Geo::Distance::Google> - While in the Geo::Distance, namespace this isn't
actually related to Geo::Distance at all.  Might be useful.

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

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

