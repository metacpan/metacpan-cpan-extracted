###################################################################
# Geo::Location::TimeZone
# $Id: TimeZone.pm,v 1.4 2007/02/06 22:29:01 bc Exp $
# Copyright (C) 2007 Bruce Campbell <beecee@cpan.zerlargal.org>
# ( Change the 'beecee' in the address above to the name of the package )
#
# This is a perl library intended to provide basic timezone information
# about a given geographic location.  
#
###########################################################################
#
#


=head1 NAME

Geo::Location::TimeZone - Find the timezone for a given location.

=head1 SYNOPSIS

  use Geo::Location::TimeZone;
  my $gltzobj = Geo::Location::TimeZone->new();
  # 54.3 degrees North, 4.8 degrees East - Amsterdam-ish.
  my $tzname = $gltzobj->lookup( lat => 54.3, lon => 4.8 );
  print "$tzname\n";

=head1 DESCRIPTION

Geo::Location::TimeZone provides a basic lookup of timezone information
based on a geographic location.  The boundaries in the internal database
are relatively coarse in order to keep the size (and lookup speed) of this 
library low.

The lookup is done in two parts; first a fall-back timezone is calculated,
based on the 15 degree intervals of longitude.  Secondly, the internal
database is consulted to see if more specific data is available.

The names of the timezones returned are according to the 'posix' directory
of the author's zoneinfo directory.  Some of these are usable with the
L<DateTime::TimeZone> library.

=cut

package Geo::Location::TimeZone;

use strict;
use Math::Polygon;

use vars qw/$VERSION/;
$VERSION = "0.1";

=head1 METHODS

=head2 new

This creates a new object.

=cut

sub basename {
	my $self = shift;
	return( "Geo::Location::TimeZone" );

}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = { };

	$self->{VERSION} = $VERSION;

	bless($self, $proto);

	return( $self );
}

# The child libraries call this via ISA inheritance and Class::Singleton's
# _new_instance
sub _init {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = { @_ };

	bless($self, $proto);

	return( $self );
}


=head2 lookup

This performs a lookup, and returns a text string of the timezone that the
supplied location is within (or undef).  No offset is returned, as that 
involves doing daylight savings calculations which are better done inside 
other modules.  

A %hash is taken as arguments, being 'lat' and 'lon', corresponding to the
latitude and longitude of the location, expressed in decimal degrees in the
WGS84 datum.  If a third argument, 'copyright' is supplied, the return 
value will be the copyright string attached to that particular item of data.

=cut

# Note (version 0.2) that as the data is stored in the child libraries in 
# binary form, the first lookup in a given segment will take slightly longer 
# while the data is unpacked into a usable form.  Following lookups within the 
# same segment will run much faster.  The size of each segment is 15 by 15 
# degrees.

=pod

Note that you may not get the timezone that you were expecting, due to 
a shortcut taken within the code.  For example, if you looked up the 
location for Narbonne, France, you might get back 'Europe/Andorra' instead
of 'Europe/Paris'.  This is because the GeoData source for the library
has major timezone boundaries, not country boundaries.  The coordinates
of major areas are known to the library, and it finds the 'closest' one
to the supplied location.

=cut

sub lookup {
	my $self = shift;

	my %args = ( @_ );

	my $retval = undef;
	my $retcopy = undef;

	# Boundaries.
	my %checkbounds = (	"lat" => [-90,90],
				"lon" => [-180,180],
				);

	my $fkeys = 0;
	my $gkeys = 0;

	# Make sure that the arguments supplied are within expected boundaries.
	# We don't wrap the coordinates around.
	foreach my $kkey( keys %checkbounds ){
		next unless( defined( $checkbounds{"$kkey"} ) );
		$fkeys++;
		next unless( defined( $args{"$kkey"} ) );
		next if( $args{"$kkey"} !~ /^\s*(\-|\+)?\d+(\.\d+)?\s*$/ );
		next if( $args{"$kkey"} < ${$checkbounds{"$kkey"}}[0] );
		next if( $args{"$kkey"} > ${$checkbounds{"$kkey"}}[1] );
		$gkeys++;
	}

	if( $fkeys > 0 && $gkeys == $fkeys ){
		# Everything matched.  Calculate the initial timezone,
		# and incidentally the polygon limit for longitude.
		my $lonoff = int( ( abs($args{"lon"}) + 7.5 ) /15 );

		# Set 'GMT-foo', 'GMT+foo' or 'GMT'; do not return
		# 'GMT-0' or 'GMT+0'.  Not enough systems know about
		# UTC.
		if( $args{"lon"} < -7.5 ){
			$lonoff = "-" . $lonoff;
			$retval = "Etc/GMT" . $lonoff;
			$retcopy = "Calculated";
		}elsif( $args{"lon"} > 7.5 ){
			$retval = "Etc/GMT+" . $lonoff;
			$retcopy = "Calculated";
		}else{
			$retval = "Etc/GMT";
			$retcopy = "Calculated";
		}

		# Calculate a similar offset for the latitude.
		my $latoff = int( ( abs($args{"lat"}) + 7.5 ) /15 );
		if( $args{"lat"} < -7.5 ){
			$latoff = "-" . $latoff;
		}

		# Get a list of polygons in that area.
		# This is good to prove the process.  Really need
		# to seperate the data into seperate files.
		my $zulu = $self->zulu( $lonoff );

		my $toload = $self->basename . "::" . $zulu;

		my %data = ();
		my $dataref = undef;

		# Class::Singleton.
		if( $self->loadclass( $toload ) ){
			my $doload = $toload . "::instance";
			# eval { %data = %{*{"$doload"}}; };
			{
				# no strict 'refs';
				# $dataref = ($doload)->();
				$dataref = $toload->instance();

				if( defined( $dataref ) ){
					my $tref = ref $dataref;
					# print STDERR "Something in 0  - $doload - $tref - $dataref \n";
				}else{
					# print STDERR "Nothing in 0 - $doload\n";
				}
			}
		}else{
			# print STDERR "Unable to load library $toload - $lonoff, $latoff\n";
		}

		if( defined( $dataref->{'data'}{"$lonoff"}{"$latoff"} ) ){
			# print STDERR "Found data for $lonoff and $latoff\n";


			# Remember which matching polygon has the smallest
			# area, as we want to return the 'best' match.
			my $smallarea = -1;
			my $smallname = undef;

			my %foundzs = ();
			foreach my $kkey( keys %{$dataref->{'data'}{"$lonoff"}{"$latoff"}} ){
				if( $kkey =~ /^def/ ){
					$foundzs{"$kkey"}++ if( $kkey =~ /^def_z/ );
					next;
				}
				# New method to save on space in the library.
				# Store in the library pack()'d versions of 
				# the floating point numbers, then unpack 
				# into the polygon variable, but only do so
				# for the bits that are checked.
				if( defined( $dataref->{'data'}{"$lonoff"}{"$latoff"}{"$kkey"}{"f"} ) ){
					$dataref->{'data'}{"$lonoff"}{"$latoff"}{"$kkey"}{"p"} = $dataref->do_unpack( string => $dataref->{'data'}{"$lonoff"}{"$latoff"}{"$kkey"}{"f"}, return => "listpoints" );
					delete( $dataref->{'data'}{"$lonoff"}{"$latoff"}{"$kkey"}{"f"} );
					# Time to unpack the numbers for this
					# one, then remove it.  Since the doc
					# for pack mentions that precision of
					# floats may not be preserved or 
					# readable across various machines, 
					# we store each number as a short
					# and long for a total of 48 bits per
					# number, 96 bits per point; 12 bytes.
					# To ensure that this library is 
					# usable on all platforms, we use
					# network byte order.  We then run 
					# into having only unsigned numbers,
					# so we subtract 360 from the short
					# to get the original number.  
					# Work through the 'f' string, taking
					# 12 bytes at a time until it is all
					# gone.

				}

				# new wants a list of [x,y],[x,y] .  how can I
				# get that from a list of [x,y,x,y,x,y] ?  Not
				# easily.  Better to incur the expense in 
				# build-data.
				my $poly = Math::Polygon->new( @{$dataref->{'data'}{"$lonoff"}{"$latoff"}{"$kkey"}{"p"}} );
				# print STDERR "Random number $kkey with data for " . $args{"lon"} . " and " . $args{"lat"} . " poly has " . $poly->nrPoints . " points X - " . $dataref->{'data'}{"$lonoff"}{"$latoff"}{"$kkey"}{"z"} . " X\n";

				if( $poly->contains( [ $args{"lon"}, $args{"lat"} ] ) ){
					my $curarea = $poly->area;
					if( $smallarea != - 1 ){
						if( $curarea < $smallarea ){
							$smallarea = $curarea;
							$smallname = $kkey;
						}
					}else{
						$smallname = $kkey;
						$smallarea = $curarea;
					}
					# print STDERR "Centroid - Is within - $curarea, $smallarea, $smallname!\n";
				}
			}

			# Did anything get found?
			if( defined( $smallname ) ){
				# See if there is a timezone for the whole
				# polygon, or whether we should find the
				# closest matchin point.
				$retcopy = $dataref->{'data'}{"$lonoff"}{"$latoff"}{"$smallname"}{"c"};
				if( defined( $dataref->{'data'}{"$lonoff"}{"$latoff"}{"$smallname"}{"z"} ) ){
					$retval = $dataref->{'data'}{"$lonoff"}{"$latoff"}{"$smallname"}{"z"};
				}else{
					# Must work through them.
					my $c_dist = -1;
					my $c_name = undef;
					my $d_dist = -1;
					my $d_name = undef;
					foreach my $curtz( keys %{$dataref->{'data'}{"$lonoff"}{"$latoff"}{"$smallname"}} ){
						next unless( $curtz =~ /^z/ );
						my @tsplit = split( ',', $dataref->{'data'}{"$lonoff"}{"$latoff"}{"$smallname"}{"$curtz"} );
						my $curdist = $self->distance( [ $args{"lon"}, $args{"lat"} ], [ $tsplit[0], $tsplit[1] ] );
						if( $curdist < $c_dist || $c_dist == -1 ){

							# If a rough effective
							# radius has been 
							# supplied, disregard
							# this point.  BUT, if
							# there wasn't a better
							# match, we'll still
							# use it.
							if( defined( $tsplit[3] ) ){
								if( $curdist < $tsplit[3] ){
									$c_dist = $curdist;
									$c_name = $tsplit[2];
								}elsif( $curdist < $d_dist || $d_dist == -1 ){
									$d_dist = $curdist;
									$d_name = $tsplit[2];
								}
							}else{
								$c_dist = $curdist;
								$c_name = $tsplit[2];
							}
						}
					}

					# Return something.
					if( defined( $c_name ) ){
						$retval = $c_name;
					}elsif( defined( $d_name ) ){
						$retval = $d_name;
					}
				}
			}else{
				# See if there is a default timezone known; 
				# this overrides the calculated value.
				if( defined( $dataref->{'data'}{"$lonoff"}{"$latoff"}{"def_z"} ) ){
					$retval = $dataref->{'data'}{"$lonoff"}{"$latoff"}{"def_z"};
					if( defined( $dataref->{'data'}{"$lonoff"}{"$latoff"}{"def_c"} ) ){
						$retcopy = $dataref->{'data'}{"$lonoff"}{"$latoff"}{"def_c"};
					}
				}else{
					# Must work through them.
					my $c_dist = -1;
					my $c_name = undef;
					foreach my $curtz( keys %foundzs ){
						my @tsplit = split( ',', $dataref->{'data'}{"$lonoff"}{"$latoff"}{"$curtz"} );
						my $curdist = $self->distance( [ $args{"lon"}, $args{"lat"} ], [ $tsplit[0], $tsplit[1] ] );
						if( $curdist < $c_dist || $c_dist == -1 ){
							$c_dist = $curdist;
							$c_name = $tsplit[2];
						}
					}
					if( defined( $c_name ) ){
						$retval = $c_name;
						# Most coordinates came from
						# Wikipedia.
						$retcopy = "GPL";
					}
				}
			}
		}else{
			# print STDERR "No matches found\n";
		}
	}

	if( defined( $args{"copyright"} ) ){
		return( $retcopy );
	}else{
		return( $retval );
	}
}

# 0.2 stuff.
# =head2 datetime_str 
# 
# This takes a given string returned from
# 
# The text string can be used against the L<DateTime::TimeZone>
# module.


# =head2 boundary
# 
# This provides the boundaries of the supplied timezone (single argument), 
# where that data is within the database.  Note that as the database only 
# stores exceptions to the calculated zones (15 degree increments, offset 
# by 7.5 degrees), this will produce some unexpected results.  Eg, a request 
# for the boundaries of 'Etc/GMT' will B<NOT> produce an outline of Western 
# Europe, even though it protrudes into the 15 degree band between longitude 
# -7.5 and 7.5 and keeps a different timezone.
# 
# As all the known data is checked for the matching timezone, this routine
# may take some time to return. The return is a %hash of polygons matching, 
# in lon,lat notation (X,Y).
# 
# =cut

sub boundary {
	my $self = shift;

	my $match = shift;
	my %rethash = ();

	# This is going to be intensive.
	for ( my $offs = -12 ; $offs <= 12 ; $offs++ ){
		my $zulu = $self->zulu( $offs );

		my $toload = $self->basename . "::" . $zulu;
		next unless( $self->loadclass( $toload ) );
		
		my $dataref = $toload->instance();

		foreach my $lonkey( keys %{$dataref->{"data"}} ){
			next unless( defined( $match ) );
			foreach my $latkey( keys %{$dataref->{"data"}{"$lonkey"}} ){
				foreach my $rkey( keys %{$dataref->{"data"}{"$lonkey"}{"$latkey"}} ){
					if( $dataref->{"data"}{"$lonkey"}{"$latkey"}{"$rkey"}{"z"} eq $match ){
						if( defined( $dataref->{"data"}{"$lonkey"}{"$latkey"}{"$rkey"}{"f"} ) ){
							$dataref->{'data'}{"$lonkey"}{"$latkey"}{"$rkey"}{"p"} = $dataref->do_unpack( string => $dataref->{'data'}{"$lonkey"}{"$latkey"}{"$rkey"}{"f"}, return => "listpoints" );
							delete( $dataref->{'data'}{"$lonkey"}{"$latkey"}{"$rkey"}{"f"} );
						}
						push @{$rethash{"$rkey"}}, @{$dataref->{"data"}{"$lonkey"}{"$latkey"}{"$rkey"}{"p"}};
					}
				}
			}
		}
	}

	return( %rethash );

}

=head2 zulu

Returns the letter code for the supplied hour offset (eg, 2 will return B).
This is used to work out which sub-library to load into memory to perform 
the lookup.

=cut

sub zulu {
	my $self = shift;

	my $arg = shift;

	my %zulus = (	"0",	"Z",
			"-0",	"Z",
			"+0",	"Z",
			"1",	"A",
			"+1",	"A",
			"2",	"B",
			"+2",	"B",
			"3",	"C",
			"+3",	"C",
			"4",	"D",
			"+4",	"D",
			"5",	"E",
			"+5",	"E",
			"6",	"F",
			"+6",	"F",
			"7",	"G",
			"+7",	"G",
			"8",	"H",
			"+8",	"H",
			"9",	"I",
			"+9",	"I",
			"10",	"K",
			"+10",	"K",
			"11",	"L",
			"+11",	"L",
			"12",	"M",
			"+12",	"M",
			"-1",	"N",
			"-2",	"O",
			"-3",	"P",
			"-4",	"Q",
			"-5",	"R",
			"-6",	"S",
			"-7",	"T",
			"-8",	"U",
			"-9",	"V",
			"-10",	"W",
			"-11",	"X",
			"-12",	"Z",
		);

	if( defined( $zulus{"$arg"} ) ){
		return( $zulus{"$arg"} );
	}else{
		return( undef );
	}
}

# Work out the distance between two points.  Classic A^2 + B^2 = C^2 routine.
sub distance {
	my $self = shift;
	my ($point1, $point2) = (@_);

	my $diffX = 0;
	my $diffY = 0;

	if( ${$point1}[0] > ${$point2}[0] ){
		$diffX = ${$point1}[0] - ${$point2}[0];
	}else{
		$diffX = ${$point2}[0] - ${$point1}[0];
	}
	if( ${$point1}[1] > ${$point2}[1] ){
		$diffY = ${$point1}[1] - ${$point2}[1];
	}else{
		$diffY = ${$point2}[1] - ${$point1}[1];
	}

	my $tans = ( $diffX * $diffX ) + ( $diffY * $diffY );

	if( $tans != 0 ){
		return( sqrt( abs( $tans ) ) );
	}else{
		# sqrt of 0 
		return( 0 );
	}
}

sub version {
	my $self = shift;

	return( $self->{'VERSION'} );
}

sub loadclass {
	my $self = shift;
	my $arg = shift;

	my $retval = 0;

	eval "require $arg";

	if( $@ ){
		# print STDERR "Return message was $@\n";
	}else{
		$retval++;
	}

	return( $retval );
}

# 0.2 stuff
# =head2 do_pack
# 
# This is a helper routine used in the compression of GeoData so the overall
# size of the child libraries is kept low.  It takes a %hash of arguments,
# comprising either of a Math::Polygon object as 'poly', or a lat/lon pair
# as 'lat' and 'lon' (decimal degrees).  It returns a single binary string
# representing the data stored.
# 
# Each point supplied is converted to two shorts and two longs, in 'network'
# byte order, for a total of 12 bytes per point.  Clueful people will note
# that pack() does not support signed shorts and longs, and will read the
# comments in the library code next.
# 
# =cut
# 
# This uses pack to store a given point (supplied as two signed floating
# point numbers in the hash; lat,lon) into 96 bits (12 bytes).  To ensure
# that this library is usable on all platforms, we store the numbers in
# network order as an unsigned short (whole number portion) and an unsigned 
# long (fraction portion).  To get around the issue of negative numbers being
# passed to this routine (as is the case in 3 out of four corners of the
# world), all numbers are bumped up at least once until they are positive
# (increments of 180 for lat, 360 for lon).
sub do_pack {
	my $self = shift;
	my %args = ( @_ );

	my $retstr = undef;

	# If we have a polygon to deal with.
	if( defined( $args{"poly"} ) ){
		# Walk through the points that are returned, and call ourselves
		# again on each point.  Math::Polygon returns points in X,Y 
		# order, but since this is a Geo-related application, the
		# data is stored in lat,lon order.
		foreach my $point( $args{"poly"}->points ){
			$retstr .= $self->do_pack( lat => ${$point}[1], lon => ${$point}[0] );
		}

	}elsif( defined( $args{"lat"} ) && defined( $args{"lon"} ) ){

		# Push them into positive space so we can store them as 
		# unsigned numbers.
		$args{"lat"} += 180;
		$args{"lon"} += 360;

		# Keep bumping them to positive.
		while( $args{"lat"} < 0 ){
			$args{"lat"} += 180;
		}
		while( $args{"lon"} < 0 ){
			$args{"lon"} += 360;
		}

		# Seperate the numbers out.
		foreach my $workkey( "lat", "lon" ){
			next unless( $args{"$workkey"} =~ /^(\d+)(\.(\d+))?$/ );
			my $large = $1;
			my $frac = defined( $3 ) ? $3 : 0;

			$retstr .= pack "nN", $large, $frac;
		}
	}else{
		# Someone hasn't read the documentation.  Either a poly
		# or lat/lon are supplied.
	}

	return( $retstr );
}

# =head2 do_unpack
# 
# This reverses the packing done by do_pack.  It takes a hash of arguments
# being:
# 
# =over
# 
# =item string
# 
# The binary string to unpack.  This should be a multiple of 12 bytes.
# 
# =item return
# 
# How to return the data.  Possible return types are 'latlon', which will
# return a @list of the latitude and longitude, 'point', which will return
# a @list of X and Y values, 'listpoints', which will return a @list of
# points (each a sub-@list), and 'poly' which will return a prepared 
# Math::Polygon object.  Note that the 'latlon' and 'point' returns will only
# process the first 12 bytes.
# 
# =over
# 
# =cut

sub do_unpack {
	my $self = shift;

	my %args = ( @_ );

	my @retlist = ();
	my $retobj = undef;


	# The polygon preparation is done at the end.
	my $dopoly = 0;
	my $listpoints = 0;
	my $latlon = 0;
	if( $args{"return"} eq "poly" ){
		$dopoly = 1;
		$args{"return"} = "listpoints";
	}elsif( $args{"return"} eq "listpoints" ){
		$listpoints = 1;
	}elsif( $args{"return"} eq "latlon" ){
		$latlon = 1;
	}

	# Run through the data that we have.
	my $stillgoing = 1;
	while( $stillgoing ){
		$stillgoing = 0;
		my $thisdata = undef;

		# Split the data into 12byte segments.
		( $thisdata, $args{"string"} ) = split( /............/s, $args{"string"}, 2);

		# Skip if there is not enough data left.
		next unless( defined( $thisdata ) );
		next unless( length( $thisdata ) == 12 );
		$stillgoing = $listpoints;

		# Unpack the data.
		my ( $latwhole, $latfrac, $lonwhole, $lonfrac ) = unpack( "nNnN", $thisdata );

		# Add the values together.  Gotta love perl at times, being
		# able to treat numbers as strings then as numbers.
		$latwhole = $latwhole . "." . $latfrac;
		$lonwhole = $lonwhole . "." . $lonfrac;

		# Apply the decrements to get signed values again.
		$latwhole -= 180;
		$lonwhole -= 360;

		# Make the numbers reasonable.
		while( $latwhole > 180 ){
			$latwhole -= 180;
		}
		while( $lonwhole > 360 ){
			$lonwhole -= 360;
		}

		# Work out how to return them.
		if( $listpoints ){
			push @retlist, [$lonwhole, $latwhole];
		}elsif( $latlon ){
			push @retlist, $latwhole, $lonwhole;
		}else{
			push @retlist, $lonwhole, $latwhole;
		}
	
	}

	# Decide what to return.
	if( $dopoly ){
		$retobj = Math::Polygon->new( @retlist );
		return( $retobj );
	}else{
		return( @retlist );
	}
}

=head1 AUTHOR

Bruce Campbell, 2007.  See http://cpan.zerlargal.org/Geo::Location::TimeZone

=head1 INTELLECTUAL PROPERTIES AND COPYRIGHT

In finding the Geodata used for this, the author ran into the common problem 
of Geographic data being held under very restrictive usage licenses, or 
being unavailable for free (as in price).  Hence, we have this listing
to avoid any issues.

=over

=item CODE 

Copyright (c) 2007 Bruce Campbell.  All rights reserved.  This program is 
free software; you can redistribute it and/or modify it under the same 
terms as perl itself.

=item Base Zones

Based on the work of the 1884 International Prime Meridian Conference.  No
copyright is claimed.

=item Derived data

A number of boundaries have been derived from direct observation, or laws 
defining administrative boundaries.  Where this is the case, no copyright
is claimed on the data.

=item Australia

To be sourced from official seperation of states.

=item UK/Ireland (GMT)

To be sourced from UK boundaries on international waters.

=item Spain/Portugal

To be sourced from water boundaries, and border line.

=item Central European Time

To be sourced from water boundaries, German/Polish border.

=item USA

To be sourced from decrees in Congress.

=item All other zones

Sourced from ESRI's timezone collection, which lists the following sources:

ArcWorld 1:3M 20020218, ArcUSA 1:2M, ArcAtlas, Rand McNally Int., www.nunavutcourtofjustice.ca, www.nunavut.com, www.nrc.ca, DMTI Spatial Inc. - 2 to 50 .

The following paragraph within the source data seems to cover the release
of Geodata within this package:

Geodata is redistributable without a Value-Added Software Application (i.e., adding the sample data to an existing, [non]commercial data set for redistribution) with proper metadata and source/copyright attribution to the respective data vendor(s).

=back

=cut

# The master data for this library lives in a hash called 'data' in 
# sub libraries.  The hash is 4-levels, 
# consisting of lonoff, latoff, random-key, and finally,
# 'p' (for poly),'z' (for zone), and 'c' (for copyright)
# lonoff and latoff are the result of putting the lat/lon into 15 degree 
# increments, from -12 to 12, and -6 to 6.
# random-key is just that; a random-key.
# The 'p'oly is a @list of X,Y values that Math::Polygon likes for input.
# The 'z'one is a text string that DateTime::TimeZone hopefully likes.
# The 'c'opyright is a text string by which people can lookup where the
#   data came from.
# The script which generates this data is in b/build-data.pl
1;
