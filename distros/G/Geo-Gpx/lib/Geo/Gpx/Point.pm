package Geo::Gpx::Point;
use strict;
use warnings;

our $VERSION = '1.10';

=encoding utf8

=head1 NAME

Geo::Gpx::Point - Class to store and edit GPX Waypoints

=head1 SYNOPSIS

  use Geo::Gpx::Point;

=head1 DESCRIPTION

L<Geo::Gpx::Point> provides a data structure for GPX points and provides accessor methods to read and edit point data.

=cut

use Geo::Gpx;
use Geo::Coordinates::Transform;
use Math::Trig;
use Carp qw(confess croak cluck);
use Scalar::Util qw( blessed );
use vars qw($AUTOLOAD %possible_attr);
use overload ('""' => 'as_string');

# file-scoped lexicals
my @attr = qw/ lat lon ele time magvar geoidheight name cmt desc src link sym type fix sat hdop vdop pdop ageofdgpsdata dgpsid extensions /;
$possible_attr{$_} = 1 for @attr;

=head2 Constructor Method

=over 4

=item new( lat => $lat, lon => $lon [, ele => $ele, desc => $desc, … ] )

Create and return a new point as per the fields provided, which can be any of C<lat lon ele time magvar geoidheight name cmt desc src link sym type fix sat hdop vdop pdop ageofdgpsdata dgpsid>. Most expect numberial values except: C<name>, C<cmt>, C<desc>, C<src>, C<sym>, C<type>, C<fix> that can contain strings.

C<lat> and C<lon> are required, all others keys are optional.

  %fields = ( lat => 47.0871, lon => 70.9318, ele => 808.000, name => 'MSA', desc => 'A nice view of the River at the top');
  $pt = Geo::Gpx::Point->new( %fields );

The C<link> field is expected to be structured as:

  link => { href => 'http://hexten.net/', text => 'Hexten', type => 'Blah' },

=back

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %fields = @_;
    my $wpt = {};
    bless( $wpt, $class);

    foreach my $key ( keys %fields ) {
        if ( $possible_attr{ $key } ) {
            $wpt->{ $key } = $fields { $key }
        } else { croak "field '$key' not supported" }
    }

    if (defined $wpt->{time} and $wpt->{time} =~ /-|:/ ) {
        $wpt->{time} = Geo::Gpx::_time_string_to_epoch( $wpt->{time} )
    }
    return $wpt
}

=over 4

=item flex_coordinates( $lat, $lon, %fields )

Takes latitude and longitude decimal values or strings and returns a C<Geo::Gpx::Point> object. The latitude should always appear before the longitude and both can be in formatted form (i.e Degrees, Minutes, Seconds or "dms") and the constructor will attempt to convert them to decimals. Any other I<%fields> are optional.

  $pt = Geo::Gpx::Point->flex_coordinates( '47.0871', '-70.9318', desc => 'Mont Ste-Anne' );

If a string reference is passed as the first argument (instead of I<$lat> and I<$lon>), the constructor will attempt to parse it as coordinates (decimal-form only). For instance you can simply call C<< flex_coordinates( '47.0871 -70.9318' ) >> with or without a comma along with optional fields.

  $str_ref = \'47.0871 -70.9318';
  $pt = Geo::Gpx::Point->flex_coordinates($str_ref, desc => 'Mont Ste-Anne' );

=back

=cut

sub flex_coordinates {
    my ($proto, $lat, $lon, %fields) = shift;
    # objective of this constructor is to be super flexible, for additionl safety do not use
    # if string ref provided, expect coord in single string (decimal form only I think)
    if (ref $_[0]) {
        $lat = shift;
        $lat = $$lat;
        $lat =~ s/(,| )+/ /g;
        ($lat, $lon) = split ' ', $lat;
        %fields = @_
    } else { ($lat, $lon, %fields) = @_ }
    croak 'flex_coordinates takes at least 2 arguments: latitude and longitude'
                                                            unless ($lon);
    my $class = ref($proto) || $proto;

    $lat =~ s/N//; $lon =~ s/N//;
    $lat =~ s/E//; $lon =~ s/E//;
    $lat =~ s/S/-/; $lon =~ s/S/-/;
    $lat =~ s/W/-/; $lon =~ s/W/-/;
	# convert coord if in DM or DMS format? (they are if whitesp or >2 dots)
	if ( ( $lat =~ /\d[ \.]+\d+[ \.]/) or
           ( $lon =~ /\d[ \.]+\d+[ \.]/) ) {
        my $cnv = new Geo::Coordinates::Transform();
        my $ref = $cnv->cnv_to_dd( [ $lat, $lon ] );
        $lat = $ref->[0];
        $lon = $ref->[1]
    }
    return $class->new( lat => $lat, lon => $lon, %fields)
}

=over 4

=item clone()

Returns a deep copy of the C<Geo::Gpx::Point>.

  $clone = $ggp->clone;

=back

=cut

sub clone {
    my $pt = shift;
    croak 'clone() expects no arguments' if @_;
    my %fields;
    foreach my $key (keys %{$pt}) {
        $fields{$key} = $pt->{$key}
    }
    return $pt->new( %fields )
}

=head2 AUTOLOAD Methods

=over 4

=item I<field>( $value )

Methods with respect to fields of the object can be autoloaded.

Possible fields consist of those listed and accepted by C<new()>, specifically:
lat, lon, ele, time, magvar, geoidheight, name, cmt, desc, src, link, sym, type, fix, sat, hdop, vdop, pdop, ageofdgpsdata, and dgpsid.

Some fields may contain a value of 0. It is safer to check if a field is defined with C<< if (defined $point->ele) >> rather than C<< if ($point->ele) >>.

Caution should be used if setting a I<$value> as no checks are performed to ensure the value is appropriate or in the proper format.

=back

=cut

sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;
    $attr =~ s/.*:://;
    return unless $attr =~ /[^A-Z]/;  # skip DESTROY and all-cap methods
    croak "invalid attribute method: -> $attr()" unless $possible_attr{$attr};
    $self->{$attr} = shift if @_;
    return $self->{$attr}
}

=head2 Object Methods

=over 4

=item distance_to( $pt or lat => $lat, lon => $lon, [ %options ] )

Returns the distance in meters from the C<Geo::Gpx::Point> I<$pt> or from the coordinates provided by I<$lat> and I<$lon>. The distance is calculated as the straight-line distance, ignoring any topography. I<$pt> must be the first argument if specified.

I<%options> may be any of the following I<key/value> pairs (all optional):

Z<>    C<< dec => I<$decimals> >>: how many digits to return after the decimal point. Defaults to 6 but this will change to 1 or 2 in the future.
Z<>    C<< km  => I<boole> >>:     scale the return value to kilometers rather than meters (default is false).
Z<>    C<< rad => I<$radius> >>:   the earth's radius in kilometers (see below).

I<$radius> should rarely be specified unless the user knows what they are doing. The default is the global average of 6371 kilometers and any value outside the 6357 to 6378 range will be ignored. This implies that a given value would affect the returned distance by at most 0.16 percent versus the global average.

=back

=cut

sub distance_to {
    my $pt = shift;

    my ($pt_to, %opts);
    if (blessed $_[0]) {
        croak 'object as argument must be a Geo::Gpx::Point' unless $_[0]->isa('Geo::Gpx::Point');
        $pt_to = shift
    }
    %opts = @_;
    $pt_to = Geo::Gpx::Point->new( lat => $opts{lat}, lon => $opts{lon} ) unless $pt_to;

    my ($radius_default, $radius, $decimal_pts, $scale);
    $radius_default = 6371;
    $radius      = $opts{rad} || $radius_default;
    $radius      = ($radius < 6357 || $radius > 6378) ? $radius_default : $radius;
    $decimal_pts = $opts{dec} || 6;
    $scale       = ( $opts{km} ) ? 1 : 1000;

    my ( $lat1, $lon1, $lat2, $lon2 ) = (
            Math::Trig::deg2rad( $pt->lat ),
            Math::Trig::deg2rad( $pt->lon ),
            Math::Trig::deg2rad( $pt_to->lat ),
            Math::Trig::deg2rad( $pt_to->lon ),
    );

    my $t = sin( ($lat2 - $lat1)/2 ) ** 2 + ( cos( $lat1 ) ** 2 ) * ( sin( ( $lon2 - $lon1 )/2 ) ** 2 );
    my $d = $radius * ( 2 * atan2( sqrt($t), sqrt(1-$t) ) );
    return sprintf( "%.${decimal_pts}f", $d * $scale )
}

=over 4

=item to_geocalc()

Returns a point as a L<Geo::Calc> object. (Requires that the L<Geo::Calc> module be installed.)

=back

=cut

sub to_geocalc {
    require Geo::Calc;
    my $pt = shift;
    croak "to_geocalc() takes no arguments" if @_;
    return Geo::Calc->new( lat => $pt->lat, lon => $pt->lon );
}

=over 4

=item to_tcx()

Returns a point as a basic L<Geo::TCX::Trackpoint> object, i.e. a point with only Position information. (Requires that the L<Geo::TCX> module be installed.)

=back

=cut

sub to_tcx {
    require Geo::TCX;
    my $pt = shift;
    croak "to_tcx() takes no arguments" if @_;
    my $xml = '<Position><LatitudeDegrees>'  . $pt->lat . '</LatitudeDegrees>' .
                        '<LongitudeDegrees>' . $pt->lon . '</LongitudeDegrees></Position';
    return Geo::TCX::Trackpoint->new( $xml )
}

=over 4

=item time_datetime ()

Return a L<DateTime> object corresponding to the time of the point. The C<time_zone> of the object will be C<< 'UTC' >>. Specify C<< time_zone => $tz >> to set a different one.

=back

=cut

# we never store a DateTime object but provide a method to return one
sub time_datetime    {
    my $pt = shift;
    my %opts = @_;
    croak 'Geo::Gpx::Point has no time field' unless $pt->time;
    my $dt = DateTime->from_epoch( epoch => $pt->time );
    $dt->set_time_zone( $opts{time_zone} ) if $opts{time_zone};
    return  $dt
}

=over 4

=item summ()

For debugging purposes mostly. Summarizes the fields of point by printing to screen. Returns nothing.

=back

=cut

sub summ {
    my $pt = shift;
    croak 'summ() expects no arguments' if @_;
    my %fields;
    foreach my $key (keys %{$pt}) {
        print "$key: ", $pt->{$key}, "\n"
    }
    return undef
}

=over 4

=item as_string()

Returns a string with the coordinates e.g. C<lat="47.0871" lon="-70.9318">.

=back

=cut

sub as_string {
    my $pt = shift;
    my %fields;
    my $str;
    $str  = 'lat="' . $pt->{lat} . '" ';
    $str .= 'lon="' . $pt->{lon} . '"';
    return $str
}

=head2 Overloaded Methods

C<as_string()> is called when using a C<Geo::Gpx::Point> instance as a string.

=head1 EXAMPLES

Coming soon.

=head1 AUTHOR

Patrick Joly C<< <patjol@cpan.org> >>.

=head1 VERSION

1.10

=head1 SEE ALSO

perl(1).

=cut

1;

