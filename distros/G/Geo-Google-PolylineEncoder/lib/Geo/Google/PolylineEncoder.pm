=head1 NAME

Geo::Google::PolylineEncoder - encode lat/lons to Google Maps Polylines

=head1 SYNOPSIS

  use Geo::Google::PolylineEncoder;

  my $points = [
                # can also take points as [lat, lon]
		{ lat => 38.5, lon => -120.2 },
	        { lat => 40.7, lon => -120.95 },
	        { lat => 43.252, lon => -126.453 },
	       ];
  my $encoder = Geo::Google::PolylineEncoder->new;
  my $eline   = $encoder->encode( $points );
  print $eline->{num_levels};  # 18
  print $eline->{zoom_factor}; # 2
  print $eline->{points};      # _p~iF~ps|U_ulLnnqC_mqNvxq`@
  print $eline->{levels};      # POP

  # in Javascript, assuming eline was encoded as JSON:
  # ... load GMap2 ...
  var opts = {
    points: eline.points,
    levels: eline.levels,
    numLevels: eline.num_levels,
    zoomFactor: eline.zoom_factor,
  };
  var line = GPolyline.fromEncoded( opts );

=cut

package Geo::Google::PolylineEncoder;

use strict;
use warnings;

use accessors qw(num_levels zoom_factor visible_threshold force_endpoints
		 zoom_level_breaks escape_encoded_points lons_first
		 points dists max_dist encoded_points encoded_levels );
use constant defaults => {
			  num_levels  => 18,
			  zoom_factor => 2,
			  force_endpoints => 1,
			  escape_encoded_points => 0,
			  visible_threshold => 0.00001,
			  lons_first => 0,
			 };
our $VERSION = 0.06;

# The constructor
sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->init(@_);
    return $self;
}

sub init {
    my ($self, %args) = @_;

    foreach my $attr (keys %{ $self->defaults }) {
	$self->$attr($self->defaults->{$attr});
    }

    foreach my $attr (keys %args) {
	$self->$attr($args{$attr});
    }
}

sub init_zoom_level_breaks {
    my $self = shift;

    # Cache for performance:
    my $num_levels = $self->num_levels;

    my @zoom_level_breaks;
    for my $i (1 .. $num_levels) {
	push @zoom_level_breaks,
	  $self->visible_threshold * $self->zoom_factor ** ($num_levels - $i);
    }

    $self->zoom_level_breaks(\@zoom_level_breaks);
}

sub reset_encoder {
    my $self = shift;
    $self->points([])->dists([])->max_dist(0)->encoded_points('')->encoded_levels('');
    # Note: calculate zoom level breaks here in case num_levels, etc. have
    # changed between encodes:
    $self->init_zoom_level_breaks;
}

sub set_points {
    my ($self, $points) = @_;

    die "points must be an arrayref!" unless UNIVERSAL::isa( $points, 'ARRAY' );

    # Internally, points are stored as [lat, lon].  Although this is less
    # readable, it is more efficient than using a hash.

    # Make a copy of the points we were given
    my @points;
    if (UNIVERSAL::isa($points->[0], 'HASH')) {
	my @keys = keys %{ $points->[0] };
	my ($lat_key) = grep( /^lat$/i, @keys );
	my ($lon_key) = grep( /^(?:lon)|(?:lng)$/i, @keys );
	@points = map { [$_->{$lat_key}, $_->{$lon_key}] } @$points;
    } elsif (UNIVERSAL::isa($points->[0], 'ARRAY')) {
	if ($self->lons_first) {
	    @points = map {[ $_->[1], $_->[0] ]} @$points;
	} else {
	    @points = map {[ $_->[0], $_->[1] ]} @$points;
	}
    } else {
	die "don't know how to handle points = $points";
    }

    return $self->points( \@points );

    return $self;
}

# The main entry point
sub encode {
    my ($self, $points) = @_;

    $self->reset_encoder
         ->set_points( $points )
	 ->calculate_distances
	 ->encode_points
	 ->encode_levels;

    my $eline = {
		 points => $self->encoded_points,
		 levels => $self->encoded_levels,
		 num_levels => $self->num_levels,
		 zoom_factor => $self->zoom_factor,
		};

    if ($self->escape_encoded_points) {
	# create string literals:
	$eline->{points} =~ s/\\/\\\\/g;
    }

    return $eline;
}

# The main function.  Essentially the Douglas-Peucker algorithm, adapted for
# encoding.  Rather than simply eliminating points, we record their distance
# from the segment which occurs at that recursive step.  These distances are
# then easily converted to zoom levels.
#
# Note: this function has been optimized and is quite long, sorry.
# Any further optimizations should probably be done in XS.
sub calculate_distances {
    my $self = shift;
    my $points = $self->points;

    my @dists;
    my $max_dist = 0;

    if (@$points <= 2) {
	# no point doing distance calcs:
	return $self->dists( \@dists )->max_dist( $max_dist );
    }

    # cache commonly used vars:
    my $visible_threshold = $self->visible_threshold;

    # Iterate through all the points, and calculate their dists

    # Each stack element contains the index of two points representing a line
    # seg that we calculate distances from.  Start off with the first & last pt:
    my @stack = ([0, @$points - 1]);

    while (@stack > 0) {
	my $current = pop @stack;

	# cache to save array lookups:
	my $current_0 = $current->[0];
	my $current_1 = $current->[1];

	# Get the two points, $A & $B:
	my ($A, $B) = ($points->[$current_0], $points->[$current_1]);

	# Cache their lon/lats to avoid unneccessary array lookups.
	# Note: we use X/Y because it's shorter, and more math-y
	my ($Ax, $Ay, $Bx, $By) = ($A->[1], $A->[0], $B->[1], $B->[0]);

	# Create a line segment between $A & $B and calculate its length
	# Note: cache the square of the seg length for use in calcs later...
	my $seg_length_squared = (($Bx - $Ax) ** 2 + ($By - $Ay) ** 2);
	my $seg_length = sqrt($seg_length_squared);
	my $seg_length_is_0 = $seg_length == 0; # cache

	# Cache the deltas in x/y for calcs later:
	my ($Bx_minus_Ax, $By_minus_Ay) = ($Bx - $Ax, $By - $Ay);

	my $current_max_dist = 0;
	my $current_max_dist_idx;
	for (my $i = $current_0 + 1; $i < $current_1; $i++) {
	    # Get the current point:
	    my $P = $points->[$i];

	    # Cache its lon/lat to avoid unneccessary hash lookups.
	    # Note: we use X/Y because it's shorter, and more math-y
	    my ($Py, $Px) = ($P->[0], $P->[1]);

	    # Compute the distance between point $P and line segment [$A, $B].
	    # Maths borrowed from Philip Nicoletti (see below).
	    #
	    # Note: we approximate distance using flat (Euclidian) geometry,
	    # rather than trying to bring the curvature of the earth into it.
	    # This greatly simplifies things, and makes the calcs faster...
	    #
	    # Note: distance calculations have been brought in-line as the
	    # majority of encoding time was spent calling the 'distance'
	    # method.  This way we can avoid passing lots of data by value,
	    # setting up the sub stack, and we can also cache some values.
	    #my $dist = $self->distance($points->[$i], $A, $B, $seg_length, $seg_length_squared);

	    my $dist;
	    if ($seg_length_is_0) {
		# The line is really just a point, so calc dist between it and $P:
		$dist = sqrt(($By - $Py) ** 2 + ($Bx - $Px) ** 2);
	    } else {
		# Thanks to Philip Nicoletti's explanation:
		#   http://www.codeguru.com/forum/printthread.php?t=194400
		#
		# So, to find out how far the line segment (AB) is from the point (P),
		# let 'I' be the point of perpendicular projection of P on AB.  The
		# parameter 'r' indicates I's position along AB, and is computed by
		# the dot product of AP and AB divided by the square of the length
		# of AB:
		#
		#       AP . AB      (Px-Ax)(Bx-Ax) + (Py-Ay)(By-Ay)
		#   r = --------  =  -------------------------------
		#       ||AB||^2                   L^2
		#
		# r can be interpreded ala:
		#
		#   r=0      I = A
		#   r=1      I = B
		#   r<0      I is on the backward extension of A-B
		#   r>1      I is on the forward extension of A-B
		#   0<r<1    I is interior to A-B
		#
		# In cases 1-4 we can simply use the distance between P and either A or B.
		# In case 5 we can use the distance between I and P.  To do that we need to
		# find I:
		#
		#   Ix = Ax + r(Bx-Ax)
		#   Iy = Ay + r(By-Ay)
		#
		# And the distance from A to I = r*L.
		# Use another parameter s to indicate the location along IP, with the
		# following meaning:
		#    s<0      P is left of AB
		#    s>0      P is right of AB
		#    s=0      P is on AB
		#
		# Compute s as follows:
		#
		#       (Ay-Py)(Bx-Ax) - (Ax-Px)(By-Ay)
		#   s = -------------------------------
		#                     L^2
		#
		# Then the distance from P to I = |s|*L.

		my $r = (($Px - $Ax) * ($Bx - $Ax) +
			 ($Py - $Ay) * ($By - $Ay)) / $seg_length_squared;

		if ($r <= 0.0) {
		    # Either I = A, or I is on the backward extension of A-B,
		    # so find dist between $P & $A:
		    $dist = sqrt(($Ay - $Py) ** 2 + ($Ax - $Px) ** 2);
		} elsif ($r >= 1.0) {
		    # Either I = B, or I is on the forward extension of A-B,
		    # so find dist between $P & $B:
		    $dist = sqrt(($By - $Py) ** 2 + ($Bx - $Px) ** 2);
		} else {
		    # I is interior to A-B, so find $s, and use it to find the
		    # dist between $P and A-B:
		    my $s = (($Ay - $Py) * $Bx_minus_Ax -
			     ($Ax - $Px) * $By_minus_Ay) / $seg_length_squared;
		    $dist = abs($s) * $seg_length;
		}
		# warn "\t$Px\t$Py\t$Ax\t$Ay\t$Bx\t$By\t$r\t$dist\n";
	    }

	    # See if this distance is the greatest for this segment so far:
	    if ($dist > $current_max_dist) {
		$current_max_dist = $dist;
		$current_max_dist_idx = $i;
		if ($current_max_dist > $max_dist) {
		    $max_dist = $current_max_dist;
		}
	    }
	}

	# If the point that had the greatest distance from the line seg is
	# also greater than our threshold, process again using it as a new
	# start/end point for the line.
	if ($current_max_dist > $visible_threshold) {
	    # store this distance - we'll use it later when creating zoom values
	    $dists[$current_max_dist_idx] = $current_max_dist;
	    push @stack, [$current_0, $current_max_dist_idx];
	    push @stack, [$current_max_dist_idx, $current_1];
	}
    }

    $self->dists( \@dists )->max_dist( $max_dist );
} # calculate_distances


# The encode_points function is very similar to Google's
# http://www.google.com/apis/maps/documentation/polyline.js
# The key difference is that not all points are encoded,
# since some were eliminated by Douglas-Peucker.
sub encode_points {
    my $self = shift;
    my $points = $self->points;
    my $dists  = $self->dists;

    my $encoded_points = "";
    my $oldencoded_points = "";
    my ($last_lat, $last_lon) = (0.0, 0.0);

    for (my $i = 0; $i < @$points; $i++) {
	my $point = $points->[$i];
	my $lat = $point->[0];
	my $lon = $point->[1];

	if (defined($dists->[$i]) || $i == 0 || $i == @$points - 1) {
	    # compute deltas, rounded to 5 decimal places:
	    my $lat_e5    = sprintf('%.5f', $lat)+0; # round()
	    my $lon_e5    = sprintf('%.5f', $lon)+0; # round()
	    my $delta_lat = sprintf('%.5f', $lat_e5 - $last_lat)+0;
	    my $delta_lon = sprintf('%.5f', $lon_e5 - $last_lon)+0;
	    ($last_lat, $last_lon) = ($lat_e5, $lon_e5);

	    $encoded_points .=
	      $self->encode_signed_number($delta_lat) .
	      $self->encode_signed_number($delta_lon);
	} else {
	    # warn "skipping point: $lat, $lon";
	}
    }

    $self->encoded_points( $encoded_points );
}


# Use compute_level to march down the list of points and encode the levels.
# Like encode_points, we ignore points whose distance (in dists) is undefined.
# See http://code.google.com/apis/maps/documentation/polylinealgorithm.html
sub encode_levels {
    my $self = shift;
    my $points = $self->points;
    my $dists  = $self->dists;
    my $max_dist = $self->max_dist;

    # Cache for performance:
    my $num_levels = $self->num_levels;
    my $num_levels_minus_1 = $num_levels - 1;
    my $visible_threshold = $self->visible_threshold;
    my $zoom_level_breaks = $self->zoom_level_breaks;

    my $encoded_levels = "";

    if ($self->force_endpoints) {
	$encoded_levels .= $self->encode_number($num_levels_minus_1);
    } else {
	$encoded_levels .= $self->encode_number($num_levels_minus_1 - $self->compute_level($max_dist));
    }


    # Note: skip the first & last point:
    for my $i (1 .. scalar(@$points) - 2) {
	my $dist = $dists->[$i];
	if (defined $dist) {
	    # Note: brought compute_level in-line as it was performing *really* slowly
	    #
	    # This computes the appropriate zoom level of a point in terms of it's
	    # distance from the relevant segment in the DP algorithm.  Could be done
	    # in terms of a logarithm, but this approach makes it a bit easier to
	    # ensure that the level is not too large.
	    #my $level = $self->compute_level($dist);
	    my $level = 0;
	    if ($dist > $visible_threshold) {
		while ($dist < $zoom_level_breaks->[$level]) {
		    $level++;
		}
	    }

	    $encoded_levels .= $self->encode_number($num_levels_minus_1 - $level);
	}
    }

    if ($self->force_endpoints) {
	$encoded_levels .= $self->encode_number($num_levels_minus_1);
    } else {
	$encoded_levels .= $self->encode_number($num_levels_minus_1 - $self->compute_level($max_dist));
    }

    $self->encoded_levels( $encoded_levels );
}


# This computes the appropriate zoom level of a point in terms of it's
# distance from the relevant segment in the DP algorithm.  Could be done
# in terms of a logarithm, but this approach makes it a bit easier to
# ensure that the level is not too large.
sub compute_level {
    my ($self, $dist) = @_;

    # Cache for performance:
    my $zoom_level_breaks = $self->zoom_level_breaks;

    my $level;
    if ($dist > $self->visible_threshold) {
	$level = 0;
	while ($dist < $zoom_level_breaks->[$level]) {
	    $level++;
	}
    }

    return $level;
}

# Based on the official google example
# http://code.google.com/apis/maps/documentation/include/polyline.js
sub encode_signed_number {
    my ($self, $orig_num) = @_;

    # 1. Take the initial signed value:
    # 2. Take the decimal value and multiply it by 1e5, rounding the result:

    # Note 1: we limit the number to 5 decimal places with sprintf to avoid
    # perl's rounding errors (they can throw the line off by a big margin sometimes)
    # From Geo::Google: use the correct floating point precision or else
    # 34.06694 - 34.06698 will give you -3.999999999999999057E-5 which doesn't
    # encode properly. -4E-5 encodes properly.

    # Note 2: we use sprintf(%.0f ...) rather than int() for similar reasons
    # (see perldoc -f int), though there's not much in it and the sprintf approach
    # ends up doing more of a round() than a floor() in some cases:
    #   floor = -30   num=-30 *int=-29  1e5=-30  %3.5f=-0.00030  orig=-0.000300000000009959
    #   floor = 119  *num=120  int=119  1e5=120  %3.5f=0.00120   orig=0.0011999999999972

    # Note 3: We don't use floor() to avoid a dependency on POSIX.  And it
    # doesn't round() anyway.

    # do this in a series of steps so we can see what's going on in the debugger:
    my $num3_5  = sprintf('%.5f', $orig_num)+0; # round at 5 decimal places
    my $num_1e5 = $num3_5 * 1e5;
    my $num      = sprintf('%.0f', $num_1e5)+0; # think int(...)

    # RT 49327: the signedness has to be determined *after* rounding
    my $is_negative = $num < 0;

    {
	# 3. Convert the decimal value to binary.  Note that a negative value
	# must be calculated using its two's complement by inverting the
	# binary value and adding one to the result.

	# Note: perl ints are already binary, but bitwise operators work on
	# the assumption they are unsigned, ie ~$num => one's complement.
	# if we 'use integer' bitwise operands are treated as signed:
	use integer; # force 2's complement

	# 4. Left-shift the binary value one bit:
	$num = $num << 1;

	# 5. If the original decimal value is negative, invert this encoding:
	# (see note on RT 49327 above)
	if ($is_negative) {
	    $num = ~$num;
	}
    }

    return $self->encode_number($num);
}

# Based on the official google example
# http://code.google.com/apis/maps/documentation/include/polyline.js
sub encode_number {
    my ($self, $num) = @_;
    no integer; # treat bitwise operands as unsigned

    # 6. Break the binary value out into 5-bit chunks (starting from the right hand side):
    # 7. Place the 5-bit chunks into reverse order:
    # 8. OR each value with 0x20 if another bit chunk follows:
    # 9. Convert each value to decimal:
    # 10. Add 63 to each value:

    my $encodeString = "";
    while ($num >= 0x20) {
	my $nextValue = (0x20 | ($num & 0x1f)) + 63;
	$encodeString .= chr( $nextValue );
	$num >>= 5;
    }

    my $finalValue = $num + 63;
    $encodeString .= chr( $finalValue );

    return $encodeString;
}

# Superficial validation of encoded points. Note that decode_points
# does not check that points are validated before decoding.
sub validate_encoded_points {
    my ($class, $encoded) = @_;

    return unless (defined $encoded && $encoded ne "");

    my @ords = unpack "c*", $encoded;

    my @out  = grep { $_ < 63 || $_ > 127 } @ords;
    return if @out;

    return 1;
}

# Decode an encoded polyline into a list of lat/lng tuples.
# adapted from http://code.google.com/apis/maps/documentation/include/polyline.js
sub decode_points {
    my ($class, $encoded) = @_;

    my $len = length( $encoded );
    my @array;

    my $index = 0;
    my $lat = 0;
    my $lon = 0;

    while ($index < $len) {
	{
	    my $b;
	    my $shift = 0;
	    my $result = 0;
	    do {
		$b = ord( substr( $encoded, $index++, 1 ) ) - 63;
		$result |= ($b & 0x1f) << $shift;
		$shift += 5;
	    } while ($b >= 0x20);
	    my $dlat = $result >> 1;
	    if ($result & 1) {
		use integer; # force 2's complement
		$dlat = ~$dlat;
	    }
	    $lat += $dlat;

	    # cut-n-paste to improve performance?
	    $shift = 0;
	    $result = 0;
	    do {
		$b = ord( substr( $encoded, $index++, 1 ) ) - 63;
		$result |= ($b & 0x1f) << $shift;
		$shift += 5;
	    } while ($b >= 0x20);
	    my $dlon = $result >> 1;
	    if ($result & 1) {
		use integer; # force 2's complement
		$dlon = ~$dlon;
	    }
	    $lon += $dlon;
	}

	push @array, { lat => $lat * 1e-5, lon => $lon * 1e-5 };
    }

    return \@array;
}

# Decode an encoded levels string into a list of levels.
# adapted from http://code.google.com/apis/maps/documentation/include/polyline.js
sub decode_levels {
    my ($class, $encoded) = @_;

    my $len = length( $encoded );
    my @levels;

    for (my $index = 0; $index < $len; $index++) {
	my $level = ord( substr( $encoded, $index, 1 ) ) - 63;
	push @levels, $level;
    }

    return \@levels;
}


1;

__END__

=head1 DESCRIPTION

This module encodes a list of lat/lon points representing a polyline into a
format for use with Google Maps.  This format is described here:

L<http://code.google.com/apis/maps/documentation/polylinealgorithm.html>

The module is a port of Mark McClure's C<PolylineEncoder.js> with some tweaks.
The original can be found here:

L<http://facstaff.unca.edu/mcmcclur/GoogleMaps/EncodePolyline/>

=head1 CONSTRUCTOR & ACCESSORS

=over 4

=item new( [%args] )

Create a new encoder.  Arguments are optional and correspond to the accessor
with the same name: L</num_levels>, L</zoom_factor>, L</visible_threshold>,
L</force_endpoints>, etc...

Note: there's nothing stopping you from setting these properties each time you
L</encode> a polyline.

=item num_levels

How many different levels of magnification the polyline has.
Default: 18.

=item zoom_factor

The change in magnification between those levels (see L</num_levels>).
Default: 2.

=item visible_threshold

Indicates the length of a barely visible object at the highest zoom level.
Default: 0.00001.  err.. units.

=item force_endpoints

Indicates whether or not the endpoints should be visible at all zoom levels.
force_endpoints is.  Probably should stay true regardless.
Default: 1=true.

=item escape_encoded_points

Indicates whether or not the encoded points should have escape characters
escaped, eg:

  $points =~ s/\\/\\\\/g;

This is useful if you'll be evalling the resulting strings, or copying them into
a static document.

B<Warning:> don't turn this on if you'll be passing the encoded points straight
on to your application, or you'll get unexpected results (ie: lines that start
out right, but end up horribly wrong).  It may even crash your browser.

Default: 0=false.

=item lons_first

Specifies the order in which coordinates passed as arrayrefs to L</encode> should be
interpreted:

  # false: lat, lon
  $encoder->encode([
     [ 38.5, -120.2 ],
     [ 40.7, -120.95 ],
  ]);

  # true: lon, lat
  $encoder->encode([
     [ -120.2, 38.5 ],
     [ -120.95, 40.7 ],
  ]);

Default: 0 = lat,lon

(Yes, the default feels wrong to the mathematician in me, but that's how Google
Maps do it, so for sake of consistency...)

=back

=head1 METHODS

=over 4

=item encode( \@points );

Encode the points into a string for use with Google Maps C<GPolyline.fromEncoded>
using a variant of the Douglas-Peucker algorithm to set levels, and the Polyline
encoding algorithm defined by Google.

Expects a reference to a C<@points> array:

  [
   { lat => 38.5, lon => -120.2 },
   { lat => 40.7, lon => -120.95 },
   { lat => 43.252, lon => -126.453 },
  ];

The individual points can also be given as arrayrefs:

  [
   [ 38.5, -120.2 ],
   [ 40.7, -120.95 ],
   [ 43.252, -126.453 ],
  ];

I<Note:> I tried to avoid this initially, because there's no standard for which
should come first: I<lat>s or I<lon>s.  But I agree, it's more convenient in
some cases so I've given you enough rope to hang yourself...  Of course you can
easily unhang yourself:  the order for arrayrefs defaults to C<lat, lon>, but
you can change that by setting L</lons_first>.

Returns a hashref containing:

  {
   points => 'encoded points string',
   levels => 'encoded levels string',
   num_levels => int($num_levels),
   zoom_factor => int($zoom_factor),
  };

You can then use the L<JSON> modules (or XML, or whatever) to pass the encoded
values to your Javascript application for use there.

=item decode_points( $encoded_polyline );

Given an encoded polyline, returns the points:

  [
   { lat => 38.5, lon => -120.2 },
   { lat => 40.7, lon => -120.95 },
   { lat => 43.252, lon => -126.453 },
  ];

Note that these will likely be slightly different from the original points due
to rounding errors during both L</encode> & decoding.

=item decode_levels( $encoded_levels );

Given encoded levels, returns the levels:

  [ 17, 16, 17 ]

=back

=head1 WHY DO MY LINES LOOK FUNNY?

Do your lines all go through the north pole?  Maybe you have your I<lon>s &
I<lat>s mixed up...  If so and you're using point arrays, you can set
L</lons_first>.

Do your points not show up at particular zoom levels?  That's not a bug, it's a
feature!  Try playing with L</visible_threshold>.

Do your encoded lines cause your browser to crash?  Sounds like a bug - file
it!

=head1 BUGS

L<https://rt.cpan.org/Dist/Display.html?Queue=Geo-Google-PolylineEncoder>

=head1 TODO

More optimization: encoding big files is *slow*.  Maybe XS implementation if
there's enough demand for it?

=head1 AUTHORS

Robert Rothenberg <rrwo@cpan.org>

Steve Purkis <spurkis@cpan.org>

Ported from Mark McClure's C<PolylineEncoder.js> which can be found here:
L<http://facstaff.unca.edu/mcmcclur/GoogleMaps/EncodePolyline/PolylineEncoderClass.html>

Some encoding ideas borrowed from L<Geo::Google>.

Bringing distance calcs in-line was Joel Rosenberg's idea:
L<http://facstaff.unca.edu/mcmcclur/GoogleMaps/EncodePolyline/gmap_polyline_encoder.rb.txt>

=head1 COPYRIGHT

Copyright (c) 2008-2010 Steve Purkis.
Released under the same terms as Perl itself.

=head1 SEE ALSO

L<http://code.google.com/apis/maps/documentation/polylinealgorithm.html>,
L<http://facstaff.unca.edu/mcmcclur/GoogleMaps/EncodePolyline/PolylineEncoderClass.html>
(JavaScript implementation),
L<http://www.usnaviguide.com/google-encode.htm> (similar implementation in perl),
L<Geo::Google>,
L<JSON::Any>

=cut
