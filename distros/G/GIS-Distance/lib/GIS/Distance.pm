package GIS::Distance;
use 5.008001;
use strictures 2;
our $VERSION = '0.14';

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

    croak 'Four arguments must be passed to distance()' if @_!=4;

    return length(
        $self->{code}->( @_, @{$self->{args}} ),
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
    
    my $distance = $gis->distance( $lat1,$lon1 => $lat2,$lon2 );
    
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

    my $distance = $gis->distance( $lat1,$lon1 => $lat2,$lon2 );

Returns a L<Class::Measure::Length> object for the distance between the
two degree lats/lons.

See L</distance_metal> to return raw kilometers instead.

=head2 distance_metal

This works just like L</distance>, but always returns raw kilometers, does no
argument checking and ignores any formula L</args>.  Calling this gets you pretty
close to the fastest bare metal speed you can get.  The speed improvements of
calling this is noticeable over millions of iterations only and you've got to
decide if its worth the safety and features you are dropping.

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
calculations you may find that adjusting your code a bit may make it
faster.  Here are some options.

Install L<GIS::Distance::Fast>.

Use L</distance_metal> instead of L</distance>.

Call the undocumented C<distance()> function that each formula module
has.  For example you could bypass this module entirely and just do:

    use GIS::Distance::Fast::Haversine;
    my $km = GIS::Distance::Fast::Haversine::distance( @coords );

The above would be the ultimate speed demon (as shown in benchmarking)
but throws away some flexibility and adds some foot-gun support.

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

L<GIS::Distance::ALT>

L<GIS::Distance::Cosine>

L<GIS::Distance::GreatCircle>

L<GIS::Distance::Haversine>

L<GIS::Distance::MathTrig>

L<GIS::Distance::Null>

L<GIS::Distance::Polar>

L<GIS::Distance::Vincenty>

These formulas are available on CPAN:

L<GIS::Distance::Fast::ALT>

L<GIS::Distance::Fast::Cosine>

L<GIS::Distance::Fast::GreatCircle>

L<GIS::Distance::Fast::Haversine>

L<GIS::Distance::Fast::Polar>

L<GIS::Distance::Fast::Vincenty>

L<GIS::Distance::GeoEllipsoid>

=head1 SEE ALSO

L<GIS::Distance::Lite> was long ago forked from GIS::Distance and modified
to have less dependencies.  Since then GIS::Distance itself has become
tremendously lighter dep-wise, and is still maintained, I suggest you not
use GIS::Distance::Lite.

L<Geo::Distance> has long been deprecated in favor of using this module.

L<Geo::Distance::XS> used to be used by L<Geo::Distance> but no longer does.

L<Geo::Inverse> seems to do some distance calculation using L<Geo::Ellipsoid>
but if you look at the source code it clearly states that the entire meat of
it is copied from Geo::Ellipsoid... so I'm not sure why it exists... just use
Geo::Ellipsoid or L<GIS::Distance::GeoEllipsoid> which wraps Geo::Ellipsoid
into the GIS::Distance interface.

L<Geo::Distance::Google> looks pretty neat.

=head1 TODO

=over 4

=item *

Create a GIS::Coord class that represents a geographic coordinate.  Then modify
this module to accept input as either lat/lon pairs, or as GIS::Coord objects.
This would make coordinate conversion as described in L</COORDINATES> automatic.
Maybe use L<Geo::Point>.

=item *

Create some sort of equivalent to L<Geo::Distance>'s closest() method.

=item *

Write a formula module called GIS::Distance::Geoid.  Some very useful info is
at L<http://en.wikipedia.org/wiki/Geoid>.

=item *

Make L<GIS::Distance::Google> (or some such name) and wrap it around
L<Geo::Distance::Google> (most likely).

=item *

Figure out why L<GIS::Distance::Polar> has issues.

=back

=head1 SUPPORT

Please submit bugs and feature requests to the GIS-Distance GitHub issue tracker:

L<https://github.com/bluefeet/GIS-Distance/issues>

=head1 AUTHORS

    Aran Clary Deltac <bluefeet@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

