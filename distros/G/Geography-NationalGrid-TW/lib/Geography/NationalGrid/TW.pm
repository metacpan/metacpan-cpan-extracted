package Geography::NationalGrid::TW;
use Exporter;
use strict;
use vars qw(@ISA $VERSION %ellipsoids %mercators);
($VERSION) = 0.08;

use constant DEFAULT_PROJECTION => 'TWD97';

use constant MIN_LATI => Geography::NationalGrid->deg2rad(21.5);
use constant MAX_LATI => Geography::NationalGrid->deg2rad(25.5);
use constant MIN_LONG => Geography::NationalGrid->deg2rad(118.75);
use constant MAX_LONG => Geography::NationalGrid->deg2rad(122.5);

@ISA = qw( Exporter Geography::NationalGrid );

%ellipsoids = (
	'int1967' => {
		'a' => 6378160.000,
		'b' => 6356774.719,
		'info' => 'Australian National',
	}, # same as grs67
	'int1924' => {
		'a' => 6378388.000,
		'b' => 6356911.946,
		'info' => 'ED50, UTM',
	}, # same as hayford1909
	'wgs84' => {
		'a' => 6378137.000,
		'b' => 6356752.3141,
		'info' => 'WGS84, ITRS, ETRS89',
	}, # same as grs80
);
$ellipsoids{'grs67'}  = $ellipsoids{'int1967'};
$ellipsoids{'grs80'}  = $ellipsoids{'wgs84'};
$ellipsoids{'hayford1909'}  = $ellipsoids{'int1924'};

%mercators = (
	'TWD67' => {
		'scalefactor' => 0.9999,
		'phio' => 0,
		'lambdao' => Geography::NationalGrid->deg2rad(121),
		'Eo' => 250000,
		'No' => 0,
		'ellipsoid' => 'int1967',
	},
	'TWD97' => {
		'scalefactor' => 0.9999,
		'phio' => 0,
		'lambdao' => Geography::NationalGrid->deg2rad(121),
		'Eo' => 250000,
		'No' => 0,
		'ellipsoid' => 'grs80',
	},
);

### PUBLIC INTERFACE

# new() does most of the work - we regularize the input to create a fully-populated object
sub new {
	my $class = shift;
	my %options = @_;

	unless ((exists $options{'Latitude'} && exists $options{'Longitude'}) ||
		(exists $options{'Easting'} && exists $options{'Northing'})
	) {
		die __PACKAGE__ . ": You must supply lat/long, or easting/northing";
	}

	my $self = bless({
		Userdata => $options{'Userdata'},
	}, $class);

	# keep constructor options
	delete $options{'Userdata'};
	while (my ($k, $v) = each %options) { $self->{'_constructor_'.$k} = $v; }

	$self->{'Projection'} = $options{'Projection'} || DEFAULT_PROJECTION;

	# gather information that will be needed in lat/long <-> east/north method
	my $mercatordata = $mercators{ $self->{'Projection'} } || die "Couldn't find Mercator projection data for $self->{'Projection'}";
	my $ellipsoiddata = $ellipsoids{ $mercatordata->{'ellipsoid'} } || die "Couldn't find ellipsoid data for $self->{'Projection'}";
	$self->{'MercatorData'} = $mercatordata;
	$self->{'EllipsoidData'} = $ellipsoiddata;

	$self->{'DefaultResolution'} = 0;

	my $flagTodo = 1;

	# if given lat/long, first make that into easting/northing
	if (exists $options{'Latitude'} && exists $options{'Longitude'}) {
		$self->{'Latitude'} = $self->deg2rad( $options{'Latitude'} );
		$self->{'Longitude'} = $self->deg2rad( $options{'Longitude'} );
		$self->_latlong2mercator;
		$flagTodo = 0;
	}

	# if got absolute northing and easting, convert that into a lat/long
	if ($flagTodo && exists $options{'Easting'} && exists $options{'Northing'}) {
		($self->{'Easting'}, $self->{'Northing'}) = ($options{'Easting'}, $options{'Northing'});
		$self->_mercator2latlong;
		$flagTodo = 0;
	}

	$self->_boundscheck;

	return $self;
}

### Main conversion methods (to transform lat/long to/from a transverse mercator projection) are inherited from the NationaGrid module

sub transform {
	my $self = shift;
	my $Projection = shift;
	return $self if $Projection eq $self->{'Projection'};
	my $a = 0.00001549;
	my $b = 0.000006521;
	my $c = 807.8;
	my $d = -248.6;
	my $e = $self->{'Easting'};
	my $n = $self->{'Northing'};
	my ($_e, $_n);
	if ($Projection eq 'TWD97') { # TWD67 -> TWD97
		$_e = $e + $c + $a * $e + $b * $n;
		$_n = $n + $d + $a * $n + $b * $e;
	} else { # TWD97 -> TWD67
		$_e = $e - $c - $a * $e - $b * $n;
		$_n = $n - $d - $a * $n - $b * $e;
	}
	return new Geography::NationalGrid::TW('Projection' => $Projection,
		'Easting' => $_e, 'Northing' => $_n);
}

### PRIVATE ROUTINES

sub _boundscheck {
	my $self = shift;

	if ($self->{'Longitude'} < MIN_LONG) { die "Point is out of the area covered by this module - too far east"; }
	if ($self->{'Longitude'} > MAX_LONG) { die "Point is out of the area covered by this module - too far west"; }
	if ($self->{'Latitude'} < MIN_LATI) { die "Point is out of the area covered by this module - too far south"; }
	if ($self->{'Latitude'} > MAX_LATI) { die "Point is out of the area covered by this module - too far north"; }
}

1;

__END__

=pod

=head1 NAME

Geography::NationalGrid::TW - Module to convert Taiwan Datum (TWD67/TM2, TWD97/TM2) to/from Latitude and Longitude

=head1 SYNOPSIS

You should _create_ the object using the Geography::NationalGrid factory class, but you still need to
know the object interface, given below.

	use Geography::NationalGrid;
	use Geography::NationalGrid::TW;
	# default TWD97
	my $point97 = new Geography::NationalGrid::TW(
		'Easting' => 302721.36,
		'Northing' => 2768851.3995,
	);
	printf("Point 97 is %f X and %f Y\n", $point97->easting, $point97->northing);
	printf("Point 97 is %f N and %f E\n", $point97->latitude, $point97->longitude);
	# transform to TWD67
	my $point67 = $point97->transform('TWD67');

=head1 DESCRIPTION

Once created, the object allows you to retrieve information about the point that the object represents.
For example you can create an object using easting / northing and the retrieve the latitude / longitude.

=head1 OPTIONS

These are the options accepted in the constructor. You MUST provide either Latitude and Longitude,
or Easting and Northing.

=over

=item Projection

Default is 'TWD97', the "TAIWAN DATUM 97".
Another projection recognized is 'TWD67', but only 'TWD97' is tested.

=item GridReference

There is no grid reference in Taiwan datum. Grid related functions are disabled.

=item Latitude

The latitude of the point. Actually should be the latitude using the spheroid related to the grid projection but for most purposes the difference is not too great. Specify the amount in any of these ways: as a decimal number of degrees, a reference to an array of three values (i.e. [ $degrees, $minutes, $seconds ]), or as a string of the form '52d 13m 12s'. North is positive degrees, south is negative degrees.

=item Longitude

As for latitude, except that east is positive degrees, west is negative degrees.

=item Easting

The number of metres east of the grid origin, using grid east.

=item Northing

The number of metres north of the grid origin, using grid north.

=item Userdata

The value of this option is a hash-reference, which you can fill with whatever you want - typical usage might be to specify C<Userdata => { Name =E<gt> 'Dublin Observatory' }> but add whatever you want. Access using the data() method.

=back

=head1 METHODS

Most of these methods take no arguments. Some are inherited from Geography::NationalGrid

=over 4

=item latitude

Returns the latitude of the point in a floating point number of degrees, north being positive.

=item longitude

As latitude, but east is positive degrees.

=item easting

How many metres east of the origin the point is. The precision of this value depends on how it was derived, but is truncated to an integer number of metres.

=item northing

How many metres north of the origin the point is. The precision of this value depends on how it was derived, but is truncated to an integer number of metres.

=item deg2string( DEGREES )

Given a floating point number of degrees, returns a string of the form '51d 38m 34.34s'. Intended for formatting, like:
$self->deg2string( $self->latitude );

=item data( PARAMETER_NAME )

Returns the item from the Userdata hash whose key is the PARAMETER_NAME.

=item transform( PROJECTION )

Transform the point to the new projection, i.e. TWD67 to TWD97 or reverse. Return the point after transformation and keep original point intact. Uses the formula proposed by John Hsieh which is supposed to provide 2 meter accuracy conversions.

=back

=head1 ACCURACY AND PRECISION

The routines used in this code may not give you completely accurate results for various mathematical and theoretical reasons. In tests the results appeared to be correct, but it may be that under certain conditions the output
could be highly inaccurate. It is likely that output accuracy decreases further from the datum, and behaviour is probably divergent outside the intended area of the grid.

This module has been coded in good faith but it may still get things wrong. Hence, it is recommended that this module is used for preliminary calculations only, and that it is NOT used under any circumstance where its lack of accuracy could cause any harm, loss or other problems of any kind. Beware!

=head1 REFERENCES

http://wiki.osgeo.org/wiki/Taiwan_datums

John Hsieh - http://gis.thl.ncku.edu.tw/coordtrans/coordtrans.aspx

=head1 AUTHOR AND COPYRIGHT

Copyright (c) 2006 Yen-Ming Lee C<< <leeym@leeym.com> >>. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
