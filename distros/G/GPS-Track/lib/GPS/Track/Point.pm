package GPS::Track::Point;

use Moo;
use Scalar::Util qw/blessed/;
use Geo::Distance;

use overload
	'!=' => sub { !shift->equals(shift) },
	'==' => \&equals;

has ["lon", "lat", "ele", "spd", "bpm", "cad" ] => (
	is => "rw",
	default => undef
);

has "time" => (
	is => "rw",
	default => undef,
	isa => sub {
		my $val = shift;
		die "Not a DateTime object!" if(defined($val) && !$val->isa("DateTime"));
	}
);

has "geoDistance" => (
	is => "ro",
	default => sub { return Geo::Distance->new(); },
);

sub distanceTo {
	my $self = shift;
	my $other = shift;

	my $otherLon = undef;
	my $otherLat = undef;

	if(blessed($other)) {
		unless($other->isa("GPS::Track::Point")) {
			die "\$other is not a GPS::Track::Point!";
		}

		$otherLon = $other->lon;
		$otherLat = $other->lat;
	}
	else {
		unless(ref($other) eq "HASH") {
			die "\$other is not a HASH reference!";
		}

		$otherLon = $other->{lon};
		$otherLat = $other->{lat};
	}

	die "\$other is missing a 'lon' value!" unless(defined $otherLon);
	die "\$other is missing a 'lat' value!" unless(defined $otherLat);

	die "\$self is missing a 'lon' value!" unless(defined $self->lon);
	die "\$self is missing a 'lat' value!" unless(defined $self->lat);

	return $self->geoDistance->distance("meter", $self->lon, $self->lat, $otherLon, $otherLat);
}

sub equals { 
	my $self = shift;
	my $other = shift;

	unless(blessed($other) && $other->isa("GPS::Track::Point")) {
		die "First argument not a GPS::Track::Point!";
	}

	my $equal = 1;

	foreach my $attr ($self->attributes) {
		my $me = $self->$attr();
		my $other = $other->$attr();

		my $bothDefined = defined($me) && defined($other);
		my $onlyOneDefined = defined($me) ^ defined($other);

		if($onlyOneDefined || ($bothDefined && $me != $other)) {
				$equal = 0;
				last;
		}
	}

	return $equal;
}
sub toString {
	my $self = shift;
	my @parts;
	foreach my $attr ($self->attributes) {
		my $value = $self->$attr();
		push(@parts, "$attr=" . (defined($value) ? $value : "undef"));
	}

	return join(" ", @parts);
}
sub toHash {
	my $self = shift;
	my $data = {};
	
	foreach my $attr ($self->attributes) {
		my $value = $self->$attr();
		if(defined($value)) {
			$data->{$attr} = $value;
		}
	}

	return $data;
}

sub attributes {
	return qw/lon lat time ele spd cad bpm/;
}

1;

__END__

=head1 NAME

GPS::Track::Point - Represent a Point of a GPS::Track

=head1 SYNOPSIS

    # Construct an empty point
    my $point = GPS::Track::Point->new();
    
    # Construct a simple point
    my $point = GPS::Track::Point->new(lon => 12, lat => 13, ele => 8848);
    my $point = GPS::Track::Point->new( { lon => 12, lat => 13 } ); # Hashref Construction supported too
    
    my $pointsEqual = $pointA == $pointB; # Watch out for floating point troubles!
    my $distance = $pointA->distanceTo($pointB);
    my $distance = $pointaA->distanceTo( { lon => 12, lat => 13 } );

=head1 DESCRIPTION

C<GPS::Track::Point> is a thin module representing a Point as parsed by L<GPS::Track>.

=head1 ATTRIBUTES

=head2 lon

   my $lon = $point->lon;
   $point = $point->lon(48);

=head2 lat

   my $lat = $point->lat;
   $point = $point->lat(9);

=head2 time

Accepts/Returns a L<DateTime>-Object or undef (if no time information is present)

   my $time = $point->time;
   my $point = $point->time(DateTime->now());

=head2 ele

   my $ele = $point->ele;
   $point = $point->ele(8848);

=head2 spd

The speed at this point, measured in meter per second.

   my $spd = $point->spd;
   my $point = $point->spd(10);

=head2 cad

   my $cad = $point->cad;
   $point = $point->cad(75);

=head2 bpm

   my $bpm = $point->bpm;
   $point = $point->bpm(180);

=head1 METHODS

=head2 distanceTo($otherPoint)

Return the 2D distance to the other point in meters.

Dies if one of the points is missing lon/lat.

   my $distance = $pointA->distanceTo($pointB);

=head2 distanceTo( { lon => X, lat => Y } )

Shorthand method to get the 2D distance to a known lon-lat-pair.

   my $distance = $pointA->distanceTo( { lon => 12, lat => 6 } );

=head2 equals($otherPoint)

Compares to point object attribute by attribute.

Equal means, that ALL atributes of both points are equal in the sense of perl. You may experience troubles with floating point precision!

Return 1 for equal points, otherwise 0.

    my $equal = $pointA->equals($pointB);

=head2 toHash()

Convert the point to a plain hash ref. Only C<defined> attributes are included as keys in the hash.

   my $point = GPS::Track::Point->new(lon => 1, lat => 2);
   my $ref = $point->toHash();
   # { lon => 1, lat => 2 }

=head2 toString()

Converts the point to a string representation. 

   my $point = GPS::Trakc::Point->new(lon => 1, lat => 2, ele => 8848);
   say $point->toString();
   # lon=1 lat=2 ele=8848 time=undef cad=undef bpm=undef spd=undef

=head1 OPERATORS

=head2 ==

Shorthand operator to call L</"equals-otherPoint"> on $pointA with $pointB as argument.

   my $areEqual = $pointA == $pointB;
   # Equivalent to $pointA->equals($pointB);

=cut
