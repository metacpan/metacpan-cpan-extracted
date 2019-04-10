package Geo::Index;


# Geo::Index
# Copyright 2019 Alexander Hajnal, All rights reserved
# 
# Alex Kent Hajnal
# --------------------------------------
# akh@cpan.org
# https://alephnull.net/software
# https://github.com/Alex-Kent/Geo-Index
# 
# This module is free software; you can redistribute it and/or modify it under 
# the same terms as Perl itself.  See the LICENSE file or perlartistic(1).


require 5.00405;

use warnings;
use strict;

use Carp;
use Math::Trig;
use POSIX qw( ceil );
use Config;

#. Note: Comments starting with #. #: and #> are used 
#. by the author to trigger syntax highlighting rules.


#. Numeric keys are smaller and faster but require a Perl with 64-bit integer support
#. When debugging this module it can be useful to manually set this to 0
use constant USE_NUMERIC_KEYS => ( $Config{use64bitint} ) ? 1 : 0;

#use constant USE_NUMERIC_KEYS => 0;  # Uncomment to force text keys
#use constant USE_NUMERIC_KEYS => 1;  # Uncomment to force numeric keys
use constant USE_PACKED_KEYS  => 0;   # Change to 1 to pack numeric keys


#. Text keys
#. ------------------------------------------------------------------------------
#. Text keys have the format "level:lat_idx,lon_idx".
#. 
#. Level is the level number, lat_idx and lon_idx are integer latitude and 
#. longitude values scaled to the key's level.  The ALL level, latitude, or 
#. longitude is represented by the string "ALL".
#. 
#. Indices using text keys require roughly twice as much memory as indices using 
#. numeric keys.  In addition, text keys are about 30% slower than numeric ones.

#. Numeric keys
#. ------------------------------------------------------------------------------
#. 64-bit numeric keys are broken down into three parts:
#.     Level      ->  bits 63..58
#.     Latitude   ->  bits 29..57
#.     Longitude  ->  bits 0..28
#. 
#. The values of latitude and longitude in numeric keys are integer values 
#. scaled to the key's level.  The ALL level, latitude, or longitude is 
#. represented by all 1 bits in the respective bitfield.

#. Packed keys
#. ------------------------------------------------------------------------------
#. Packed numeric keys are numeric keys run through pack("Q", $key)
#. 
#. There appears to be no performance benefit from using them.



#. Value for ALL for Level
#. Can also be used for masking values
use constant MASK_LEVEL  => ( 1 << 6 ) - 1;

#. Value for ALL for Latitude or Longitude
#. Can also be used for masking values
use constant MASK_LATLON => ( 1 << 29 ) - 1;

#. Used in key specifications for global [ ALL, ALL, ALL ] and polar areas [ ..., ..., ALL ]
use constant ALL => -1;





=encoding utf8

=head1 NAME

Geo::Index - Geographic indexer

=cut

use vars qw ($VERSION);
$VERSION = 'v0.0.8';

=head1 VERSION

This document describes Geo::Index version 0.0.8

=cut




#. Attempt to load C low-level code library


#. The C code is located in Index.xs is the code's root directory


#. Boilerplate for compiled code
require Exporter;
*import = \&Exporter::import;
require DynaLoader;
sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

#. Attempt to load the C low-level code library
eval { DynaLoader::bootstrap Geo::Index $VERSION; };

#. Note whether C low-level code library is available
my $C_CODE_COMPILED; 
if ($@) {
	$C_CODE_COMPILED = 0;
} else {
	$C_CODE_COMPILED = 1;
}
	
#. Choose which C function to export
@Geo::Index::EXPORT    = qw();  # Symbols to export by default
#@Geo::Index::EXPORT_OK = qw(
#    GetCCodeVersion fast_log2_double fast_log2_float ComputeAreaExtrema_float 
#    ComputeAreaExtrema_double ComputeAreaExtrema_double SetUpDistance_float HaversineDistance_float 
#    SetUpDistance_double SetUpDistance_double HaversineDistance_double 
#    );
@Geo::Index::EXPORT_OK = qw();  # Symbols to export on request




=head1 SYNOPSIS

  # Create and populate a geographic index
  
  use Geo::Index;
  
  @points = (
              { lat =>   1.0, lon =>   2.0 },
              { lat => -90.0, lon =>   0.0, name => 'South Pole' },
              { lat =>  30.0, lon => -20.0, ele => 123.4 }
            );
  $point = { lat=>10.0, lon=>20.0 };
  
  $index = Geo::Index->new();
  $index->IndexPoints( \@points );
  $index->Index( $point );
  $index->Index( [ 30, 40 ] );
  
  
  # Search index
  
  %search_options = ( sort_results => 1, radius=>5_000_000 );
  $results = $index->Search( [ -80, 20 ], \%search_options );
  print "$$results[0]{name}\n";  # Prints 'South Pole'
  
  # Get all points in the southern hemisphere
  $results = $index->SearchByBounds( [ -180, -90, 180, 0 ] );
  print "$$results[0]{name}\n";  # Also prints 'South Pole'
  
  ($closest) = $index->Closest( [ -80, 20 ] );
  print "$$closest{name}\n";     # Also prints 'South Pole'
  
  ($closest) = $index->Closest( $points[1], { post_condition=>'NONE' } );
  print "$$closest{name}\n";     # Also prints 'South Pole'
  
  ($farthest) = $index->Farthest( [ 90, 0 ] );
  print "$$farthest{name}\n";    # Also prints 'South Pole'
  
  # Compute distance in meters between two points (using haversine formula)
  
  $m = $index->Distance( { lat=>51.507222, lon=>-0.1275 }, [ -6.2, 106.816667 ] );
  printf("London to Jakarta: %i km\n", $m / 1000);
  
  $index->DistanceFrom( [ 90, 0 ] );
  $m = $index->DistanceTo( $points[1] );
  printf("Pole to pole:      %i km\n", $m / 1000);
  
=head1 DESCRIPTION

Geo::Index is a Perl module for creating in-memory geographic points indices. 
Once points have been indexed, fast searches can be run.  

Efficient searches methods include B<C<L<Search(...)|/Search( ... )>>> to get all points 
within a distance from a given point, B<C<L<SearchByBounds(...)|/SearchByBounds( ... )>>> to get all 
points in an given area, B<C<L<Closest(...)|/Closest( ... )>>> to get the closest points to a 
given point, and B<C<L<Farthest(...)|/Farthest( ... )>>> to get the farthest points from a given 
point.

Additional methods are provided to compute distances between arbitrary points 
(E<nbsp>B<C<L<Distance(...)|/Distance( ... )>>>, B<C<L<DistanceFrom(...)|/DistanceFrom( ... )>>>, and B<C<L<DistanceTo(...)|/DistanceTo( ... )>>>E<nbsp>)
and to get the size in meters of one degree or the size in degrees of one meter
at a given point (B<C<L<OneDegreeInMeters(...)|/OneDegreeInMeters( ... )>>> and B<C<L<OneMeterInDegrees(...)|/OneMeterInDegrees( ... )>>>, 
respectively).

While by default computations are done for the Earth, other bodies can be used 
by supplying appropriates radii and circumferences to B<C<L<new(...)|/Geo::Index-E<gt>new( ... )>>>.

=head1 POINTS

Geo::Index works with points on a spherical body.  Points are hash references 
containing, at a minimum, C<lat> and C<lon> entries which give the point's 
position in degrees.  Additional hash entries can be present and will be both 
ignored and preserved.  The C<L<Index(...)|/Index( ... )>>, C<L<IndexPoints(...)|/IndexPoints( ... )>>,  
C<L<Search(...)|/Search( ... )>>, C<L<Closest(...)|/Closest( ... )>>, C<L<Farthest(...)|/Farthest( ... )>>, 
C<L<Distance(...)|/Distance( ... )>>, C<L<DistanceFrom(...)|/DistanceFrom( ... )>>, and C<L<DistanceTo(...)|/DistanceTo( ... )>> 
methods add additional entries in point hashes.

The hash entries used by Geo::Gpx are shown below.  Apart from C<lat> and C<lon> 
these values are created by Geo::Gpx.  Unless noted, these values may be read but 
should not be set, altered, or deleted.

=over

=item *
B<C<lat>> - Point's latitude in degrees [ -90 .. 90 ]

=item *
B<C<lon>> - Point longitude in degrees [ -180 .. 180 )

These two values may be changed but the altered point should then be re-indexed 
using C<L<Index(...)|/Index( ... )>> before further searches are run.

=item *
B<C<data>> - The optional user data supplied when a point was created 
using the array shorthand.  This contents of this field may be freely modified 
by the user.  See C<L<Index(...)|/Index( ... )>> and C<L<IndexPoints(...)|/IndexPoints( ... )>>, below.

=item *
B<C<lat_rad>> - The point's latitude in radians [ -pi/2 .. pi/2 ]

=item *
B<C<lon_rad>> - The point's longitude in radians [ -pi .. pi )

=item *
B<C<circumference>> - Circumference (in meters) of the circle of latitude 
that the point falls on.  This is computed from the body's equatorial 
circumference assuming a spherical (not an oblate) body.

=item *
B<C<search_result_distance>> - Distance (in meters) of point from search 
point of previous search.  The distance computation assumes a spherical body 
and is computed using a ruggedized version of the haversine formula.  This 
value is only generated when C<L<Search(...)|/Search( ... )>> is called with the C<radius> 
or C<sort_results> option.  See also C<L<Distance(...)|/Distance( ... )>>, C<L<DistanceFrom(...)|/DistanceFrom( ... )>>, 
and C<L<DistanceTo(...)|/DistanceTo( ... )>>.

=item *
B<C<antipode_distance>> - Distance (in meters) of point from search 
point's antipode as determined by a previous call to C<L<Farthest(...)|/Farthest( ... )>>.
This distance is computed using a ruggedized version of the haversine formula.

=back

As a convenience, most methods allow points to be specified using a shorthand 
notation S<C<[ I<lat>, I<lon> ]>> or S<C<[ I<lat>, I<lon>, I<data> ]>>.  Points 
given in this notation will be converted to hash-based points.  If a point 
created using this notation is returned as a search result it will be as a 
reference to the hash constructed by Geo::Index and not as a reference to the 
original array.  To access the data field of a point created using the shorthand 
notation use C<$$point{'data'}> where C<$point> is a search result point.

Any fields added to the indexed points by Geo::Index can be removed using 
C<L<Sweep(...)|/Sweep( ... )>> and C<L<Vacuum(...)|/Vacuum( ... )>>.

=head1 METHODS

=cut

BEGIN {

} # END BEGIN


use fields qw(index indices positions planetary_radius planetary_diameter polar_circumference equatorial_circumference levels max_level max_size quiet);



=head2 Geo::Index-E<gt>new( ... )

=over

C<$index = Geo::Index-E<gt>new()>;

=over

Create a new empty index using default options: radius and circumferences are those of Earth, C<levels> is set to 20 (~40E<nbsp>m index resolution).

=back

C<$index = Geo::Index-E<gt>new( \@points );>

=over

Create a new index using default options and populate it with the given points.

The points in the array can be in either hash or array notation.

=back

C<$index = Geo::Index-E<gt>new( \%options );>

=over

Create a new empty index using specified options.

=back

C<$index = Geo::Index-E<gt>new( \@points, \%options );>

=over

Create a new index using specified options and populate it with the given points.

The points in the array can be in either hash or array notation.

=back

B<The options hash:>

When a Geo::Index object is created, one can specify various options to fine-tune
its behavior.  The default values are suitable for a high-resolution index of Earth.

=over

B<C<radius>>

=over

Average planetary radius (in meters).  S<(default: 6371230)>

If a C<radius> is specified but C<polar_circumference> or C<equatorial_circumference> 
are not given then they will be calculated from the radius ( 2 * pi * radius )

=back

B<C<polar_circumference>>

=over

Polar (meridional) circumference of the object the points lie on (in meters).  S<(default: 40007863)>

=back

B<C<equatorial_circumference>>

=over

Circumference at the equator of the object the points lie on (in meters).  S<(default: 40075017)>

=back

B<C<levels>>

=over

Depth of index.  S<(valid: E<gt>0, E<lt>31; default: 20)>

Note that the C<levels> parameter specifies the number of non-full-globe index 
levels to generate and NOT the deepest index level.  (Level -1, covering the 
entire globe, is always generated)  For example, setting C<levels> to 20 
generates indices at levels 0 through 19 (plus level -1).

A summary of typical tile levels is shown below.  To choose a value for the 
C<levels> option using the table add 1 to the 'Level' shown for the desired 
maximum level of detail.  The 'Grid' column shows the north-south size of each 
tile in meters at a each level.  The 'Size' column shows the initial amount of 
RAM needed for an indexed set of S<1E<nbsp>million> random points using numeric 
keys on a 64-bit system when that level is the most detailed one (sizes may grow 
moderately once searches are run).

 Level    Grid      Size              Level   Grid     Size  
 -----  ---------  ---------------    -----  -------  -------
  -1    ~40000 km  (entire planet)     12      ~5 km  ~2.4 GB
   0    ~20000 km                      13    ~2.5 km  ~2.7 GB
   1    ~10000 km  ~1.0 GB             14    ~1.2 km  ~3.1 GB
   2     ~5000 km  ~1.0 GB             15    ~600 m   ~3.3 GB
   3     ~2500 km  ~1.1 GB             16    ~300 m   ~3.6 GB
   4     ~1250 km  ~1.2 GB             17    ~150 m   ~3.8 GB
   5      ~625 km  ~1.3 GB             18     ~75 m   ~4.1 GB
   6      ~315 km  ~1.4 GB             19     ~40 m   ~4.4 GB
   7      ~155 km  ~1.5 GB             20     ~20 m   ~4.6 GB
   8       ~80 km  ~1.6 GB             21     ~10 m   ~4.9 GB
   9       ~40 km  ~1.7 GB             22      ~5 m   ~5.1 GB
  10       ~20 km  ~1.9 GB             23      ~2 m   ~5.4 GB
  11       ~10 km  ~2.1 GB             24      ~1 m   ~5.6 GB

For reference, the memory usage of the array of S<1 million> random, unindexed 
points is about S<440 MB>, growing to about S<540 MB> with index use (about 100 
bytes per point); the former amount is included in the index memory usage shown 
above.

=back

B<C<function_type>>

=over

Choose the type of low-level functions to use.
S<(default: 'C<double>' if available, 'C<perl>' otherwise)>

Geo::Index will attempt to use compiled C code to speed up certain calculations.  
If the compilation fails (or was blocked by the user) then equivalent (but 
slower) Perl code will be used.

This option can be used to explicitly request the type of code to use.  When set 
to 'C<float>' then compiled C code using single-precision floating point will 
be requested.  When set to 'C<double>' then compiled C code using double-precision 
floating point will be requested.  When set to 'C<perl>' then Perl code will be 
used.  If compiled code is unavailable then Perl code will be used regardless of 
what was requested.

Perl natively uses double-precision floating point.  On modern hardware 
double-precision is slightly faster than single-precision.  On certain platforms, 
however, it may be preferable to use single-precision instead of double-precision 
floating point.  When needed, using single-precision should not be an issue since 
the minor errors introduced from loss of precision are drowned out by the errors 
inherent in the haversine function that is used for distance calculations.

=back

=back

=back

=cut


#. Geo::Index uses C code to speed up distance computations.
#. Along with $C_CODE_COMPILED (set near top of this module), the following 
#. variables hold the current state of the compiled code:

my $ACTIVE_CODE = undef;  #. Set to the type of low-level code currently being used:
                          #. 'perl, 'double', or 'float' (the latter two being C)
my @SUPPORTED_CODE = ( ); #. List of available low-level code types
my $C_CODE_ACTIVE = 0;    #. Set true when compiled C code is being used

sub new($;$$) {
	my ( $class, $_points, $_options ) = @_;
	
	#. Allow calling as Geo::Index->new( \%options )
	if (ref $_points eq 'HASH') {
		$_options = $_points;
		$_points = undef;
	}
	
	#. Initialize instance variables
	
	my Geo::Index $self = fields::new(ref $class || $class);
	
	$self->{index}      = { };  #. The points index
	$self->{indices}    = { };  #. Indices used for each point
	$self->{positions}  = { };  #. Each point's position when indexed
	
	#. Planetary parameters
	#. 
	#. (Defaults are for the Earth)
	
	$self->{planetary_radius}         =  6371230;  #. Average radius of the object the points lie on (in m)
	$self->{polar_circumference}      = 40007863;  #. Polar circumference of the object the points lie on (in m)
	$self->{equatorial_circumference} = 40075017;  #. Circumference at the equator of the object the points lie on (in m) 
	
	if (ref $_options eq 'HASH') {
		
		if ($_options->{radius}) {
			#. A custom planetary size is being used
			$self->{planetary_radius}         = $_options->{radius};
			
			#. If not specified, circumferences are calculated from radius
			$self->{polar_circumference}      = ( $_options->{polar_circumference} )      ? $_options->{polar_circumference}      : 2 * pi * $self->{planetary_radius};
			$self->{equatorial_circumference} = ( $_options->{equatorial_circumference} ) ? $_options->{equatorial_circumference} : 2 * pi * $self->{planetary_radius};
		}
		
	}
	$self->{planetary_diameter} = 2 * $self->{planetary_radius};
	
	#. Index parameters
	
	#. Level    Grid      Size              Level   Grid     Size  
	#. -----  ---------  ---------------    -----  -------  -------
	#.  -1    ~40000 km  (entire planet)     12      ~5 km  ~2.4 GB
	#.   0    ~20000 km                      13    ~2.5 km  ~2.7 GB
	#.   1    ~10000 km  ~1.0 GB             14    ~1.2 km  ~3.1 GB
	#.   2     ~5000 km  ~1.0 GB             15    ~600 m   ~3.3 GB
	#.   3     ~2500 km  ~1.1 GB             16    ~300 m   ~3.6 GB
	#.   4     ~1250 km  ~1.2 GB             17    ~150 m   ~3.8 GB
	#.   5      ~625 km  ~1.3 GB             18     ~75 m   ~4.1 GB
	#.   6      ~315 km  ~1.4 GB             19     ~40 m   ~4.4 GB
	#.   7      ~155 km  ~1.5 GB             20     ~20 m   ~4.6 GB
	#.   8       ~80 km  ~1.6 GB             21     ~10 m   ~4.9 GB
	#.   9       ~40 km  ~1.7 GB             22      ~5 m   ~5.1 GB
	#.  10       ~20 km  ~1.9 GB             23      ~2 m   ~5.4 GB
	#.  11       ~10 km  ~2.1 GB             24      ~1 m   ~5.6 GB
	#. 
	#. Memory usage shown above is for 1 million random points using numeric keys 
	#. at various settings of the 'levels' option ('Level' is one less than the 
	#. value of the 'levels' option with 'levels' values of -1 or 0 being invalid.)  
	#. For reference, the memory usage of the array of 1 million random, unindexed 
	#. points is about 440 MB; this amount is included in the index memory usage 
	#. shown above.  The size of the points array will grow moderately (about 100 
	#. bytes per point) as the index is used.
	
	#. Depth of index
	$self->{levels} = 20;  #. ~40 m grid size at most detailed level of index
	if (ref $_options eq 'HASH') {
		$self->{levels} = int $_options->{levels} if ($_options->{levels});
	}
	#.Clip value
	if ($self->{levels} > 30) {
		$self->{levels} = 30;
	} elsif ($self->{levels} < 1) {
		$self->{levels} = 1;
	}
	
	#. Number of grid tiles in each direction at most detailed level of index
	$self->{max_size} = 2**$self->{levels};
	
	#. Index of the highest-resolution level
	$self->{max_level} = $self->{levels} - 1;
	
	#. If possible, compiled C code will be used for the distance functions
	#. If the code compiled and this is the first time new() is being called 
	#. we'll start using the compiled code by default.
	unless ( defined $ACTIVE_CODE ) {
		push @SUPPORTED_CODE, 'perl';
		
		if ( $C_CODE_COMPILED) {
			push @SUPPORTED_CODE, 'float';
			push @SUPPORTED_CODE, 'double';
			SetDistanceFunctionType('double');
		} else {
			SetDistanceFunctionType('perl');
		}
	}
	
	#. Optionally switch function type to one of 'perl', 'double' or 'float'
	if (ref $_options eq 'HASH') {
		if ( defined $_options->{function_type} ) {
			SetDistanceFunctionType( $_options->{function_type} );
		}
	}
	
	#. Optionally initialize the index with a set of points
	if ( (defined $_points) && (scalar @$_points) ) {
		$self->IndexPoints($_points);
	}
	
	$self->{quiet} = ( defined $_options->{quiet} ) ? $_options->{quiet} : 0;
	
	return $self;
}



=head2 IndexPoints( ... )

=over

C<$index-E<gt>IndexPoints( \@points );>

Add points in list to the index

If a point is added that already exists in the index and its position has 
changed then the existing index entry will be deleted and the point will be 
indexed again.  If its position has not changed then no action will be taken.

B<C<@points>>

=over

The points to add to the index

Each point in the list is either a reference to a hash containing at a minimum 
a C<lat> and a C<lon> value (both in degrees) or a reference to an array 
giving the point.  See the B<L<Points|/POINTS>> section above for details.

=back

=back

=cut



sub IndexPoints($$) {
	my ($self, $_points) = @_;
	
	foreach my $_point (@$_points) {
		my $type = ref $_point;
		
		if ( ($type eq 'ARRAY') ||  ($type eq 'HASH') ) {
			$self->Index( $_point );
			
		} else {
			croak "Unknown argument in Index: '$_point'";
		}
	}
}



sub BuildPoints($) {
	my (undef, $_in) = @_;
	my @out = ( );
	
	foreach my $_point ( @$_in ) {
		my $type = ref $_point;
		
		if ($type eq 'ARRAY') {
			#. Got array; expand arguments into a full point
			$_point = { 'lat'=>$$_point[0], 'lon'=>$$_point[1], 'data'=>$$_point[2] };
			
		} elsif ($type eq 'HASH') {
			#. Got hash; no changes needed
			
		} else {
			croak "Geo::Index::BuildPoints(...): Unknown point format '$_point'; maybe you passed a list of references instead of a reference to a list of references?\n";
		}
		
		push @out, $_point;
	}
	
	return ( wantarray ) ? @out : \@out;
}



=head2 Index( ... )

=over

C<$index-E<gt>Index( \%point );>

C<$index-E<gt>Index( \@point );>

Add a single point to the index

If the point being added already exists in the index and its position has 
changed then the existing index entry will be deleted and the point will be 
indexed again.  If its position has not changed then no action will be taken.

B<C<%point>> or B<C<@point>>

=over

The point to add to the index

This can be either a hash containing at a minimum a C<lat> and a C<lon> value 
(both in degrees) or an array giving the point.  See the B<L<Points|/POINTS>> section above 
for details.

=back

=back

=cut


sub Index($$) {
	my ($self, $_point) = @_;
	
	my $type = ref $_point;
	
	if ($type eq 'ARRAY') {
		#. Got array; expand arguments into a full point
		$_point = { 'lat'=>$$_point[0], 'lon'=>$$_point[1], 'data'=>$$_point[2] };
		
	} elsif ($type eq 'HASH') {
		#. Got hash; no changes needed
		
	} else {
		croak "Unknown argument in Index: '$_point'";
	}
	
	my $lat = $$_point{lat};
	my $lon = $$_point{lon};
	
	#: Don't reindex points that are already in the index if they haven't moved
	if ( defined $$self{positions}{$_point} ) {
		
		my $indexed_position = $$self{positions}{$_point};
		
		if (
		     ( $lat == $$indexed_position[0] ) &&
		     ( $lon == $$indexed_position[1] ) 
		   ) {
			#. Point is already indexed but hasn't moved; don't reindex
			return;
		}
		
		#. Point has moved; delete it so that it can be reindexed
		Unindex($self, $_point);
	}
	
	$$self{positions}{$_point} = [ $lat, $lon ];
	
	$$_point{lat_rad} = Math::Trig::deg2rad($lat);
	$$_point{lon_rad} = Math::Trig::deg2rad($lon);
	$$_point{circumference} = cos( $$_point{lat_rad} ) * $self->{equatorial_circumference};
	
	my ($lat_int, $lon_int) = $self->GetIntLatLon($lat, $lon);
	
	my $size = $self->{max_size};
	
	my @to_index = ();
	my $key;
	
	my ($lat_idx_0, $lon_idx_0) = $self->GetIndices($self->{max_level}, $lat_int, $lon_int);
	
	for (my $grid_level=$self->{max_level}; $grid_level>=0; $grid_level--) {
		
		#. Choose indices
		
		my $size_minus_one = $size - 1;
		if ( $lat_idx_0 == 0 ) {
			#. Near south pole
			
			if (USE_NUMERIC_KEYS) {
				if (USE_PACKED_KEYS) {
					$key = pack("Q", ( $grid_level << 58 ) | ( $lat_idx_0 << 29 ) | MASK_LATLON );
				} else {
					$key = ( $grid_level << 58 ) | ( $lat_idx_0 << 29 ) | MASK_LATLON;
				}
			} else {
				$key = [ $grid_level, $lat_idx_0, ALL ];
			}
			push @to_index, $key;
			if (USE_NUMERIC_KEYS) {
				push @{ $self->{index}{$key} }, $_point;
			} else {
				$self->AddValue( $key, $_point );
			}
			
		} elsif ( $lat_idx_0 >= $size_minus_one ) {
			#. Near north pole
			
			# Clip value
			$lat_idx_0 = $size_minus_one;
			
			if (USE_NUMERIC_KEYS) {
				if (USE_PACKED_KEYS) {
					$key = pack("Q", ( $grid_level << 58 ) | ( $lat_idx_0 << 29 ) | MASK_LATLON );
				} else {
					$key = ( $grid_level << 58 ) | ( $lat_idx_0 << 29 ) | MASK_LATLON;
				}
			} else {
				$key = [ $grid_level, $size_minus_one, ALL ];
			}
			push @to_index, $key;
			if (USE_NUMERIC_KEYS) {
				push @{ $self->{index}{$key} }, $_point;
			} else {
				$self->AddValue( $key, $_point );
			}
			
		} else {
			#. Non-polar
			
			if (USE_NUMERIC_KEYS) {
				if (USE_PACKED_KEYS) {
					$key = pack("Q", ( $grid_level << 58 ) | ( $lat_idx_0 << 29 ) | $lon_idx_0 );
				} else {
					$key = ( $grid_level << 58 ) | ( $lat_idx_0 << 29 ) | $lon_idx_0;
				}
			} else {
				$key = [ $grid_level, $lat_idx_0, $lon_idx_0 ];
			}
			
			push @to_index, $key;
			if (USE_NUMERIC_KEYS) {
				push @{ $self->{index}{$key} }, $_point;
			} else {
				$self->AddValue($key, $_point);
			}
		}
		
		$size >>= 1;
		$lat_idx_0  >>= 1;
		$lon_idx_0  >>= 1;
	}
	
	#. All points in the world get this index
	if (USE_NUMERIC_KEYS) {
		if (USE_PACKED_KEYS) {
			$key = pack("Q", ( MASK_LEVEL << 58 ) | ( MASK_LATLON << 29 ) | MASK_LATLON );
		} else {
			$key = ( MASK_LEVEL << 58 ) | ( MASK_LATLON << 29 ) | MASK_LATLON;
		}
	} else {
		$key = [ ALL, ALL, ALL ];
	}
	push @to_index, $key;
	if (USE_NUMERIC_KEYS) {
		push @{ $self->{index}{$key} }, $_point;
	} else {
		$self->AddValue($key, $_point);
	}
	
	$$self{indices}{$_point} = \@to_index;
}



=head2 Unindex( ... )

=over

C<$index-E<gt>Unindex( \%point );>

Remove specified point from index

This method will remove the point from the index but will not destroy the 
actual point.

B<C<%point>>

=over

The point to remove from the index.

Note that this must be a reference to the actual point to remove and not to a 
copy of it.  Simply specifying a point's location as a new point hash will not 
work.

=back

Added in 0.0.4 to replace the functionally identical (and now deprecated) 
C<DeletePointIndex(...)>.

=back

=cut


#. Trampoline to handle deprecated method name
sub DeletePointIndex($$) {
	my ($self, $_point) = @_;
	
	print STDERR "DeletePointIndex(...) is deprecated and will be removed in future.  " .
	             "Please update your code to use Unindex(...) instead.\n" 
	             unless $self->{quiet};
	
	#. Update method pointer to point to new code
	*Geo::Index::DeletePointIndex = *Geo::Index::Unindex;
	
	#. Fall through to new name
	if (wantarray) {
		return $self->Unindex($_point);
	} else {
		return scalar $self->Unindex($_point);
	}
}


#. Remove specified point from index
# Used by Index
sub Unindex($$) {
	my ($self, $_point) = @_;
	
	#. Remove the point from the index
	
	#. Get the full index
	my $_index = $self->{index};
	
	#. Get the list of point's index keys
	my $_indices = $$self{indices}{$_point};
	
	#. Loop through point's index keys...
	foreach my $key ( @$_indices ) {
		
		#. Look up the key's index entry
		my $_index_entry = $self->GetValue($key);
		
		#. Remove point from the index entry
		
		my $i = 0;
		#. Loop through points lying in the index entry...
		foreach my $_indexed ( @$_index_entry ) {
			if ($_point eq $_indexed) {
				#. Found point in index, delete it from the index
				splice @$_index_entry, $i, 1;
				last;
			}
			$i++;
		}
		#. Point has now been removed from index entry
		
		#. Delete the index entry if it's now empty
		
		my $formatted_key;
		if (USE_NUMERIC_KEYS) {
			$formatted_key = $key;
		} else {
			my $level = $$key[0];
			my $lat   = int $$key[1];
			my $lon   = int $$key[2];
			if ( $lon == ALL ) {
				if ( $level == ALL ) {
					$formatted_key = 'ALL:ALL,ALL';
				} else {
					$formatted_key = "$level:$lat,ALL";
				}
			} else {
				$formatted_key = "$level:$lat,$lon";
			}
			
		}
		delete $$_index{$formatted_key} unless (scalar @{$$_index{$formatted_key}});
	}
	
	#. Delete the point from the index metadata
	delete $$self{indices}{$_point};
	delete $$self{positions}{$_point};
}



#. Add a value to the index using a text key
# Used by Index
sub AddValue($$$) {
	my ($self, $key, $value) = @_;
	
	my $_index = $self->{index};
	if (USE_NUMERIC_KEYS) {
		push @{ $$_index{$key} }, $value;
	} else {
		my $level = $$key[0];
		my $lat   = int $$key[1];
		my $lon   = int $$key[2];
		if ( $lon == ALL ) {
			if ( $level == ALL ) {
				push @{ $$_index{'ALL:ALL,ALL'} }, $value;
			} else {
				push @{ $$_index{"$level:$lat,ALL"} }, $value;
			}
		} else {
			push @{ $$_index{"$level:$lat,$lon"} }, $value;
		}
	}
}



#. Return the index entry for a given key
#. Keys are either 64-bit integers or array 
#. references: [ level, lat_idx, lon_idx ]
# Used by Search, Closest, Unindex, Sweep, Vacuum
sub GetValue($$) {
	my ($self, $key) = @_;
	
	my $_index = $self->{index};
	if (USE_NUMERIC_KEYS) {
		return $$_index{$key};
	} else {
		my $level = $$key[0];
		my $lat   = int $$key[1];
		my $lon   = int $$key[2];
		if ( $lon == ALL ) {
			if ( $level == ALL ) {
				return $$_index{"ALL:ALL,ALL"};
			} else {
				return $$_index{"$$key[0]:$$key[1],ALL"};
			}
		} else {
			return $$_index{"$$key[0]:$$key[1],$$key[2]"};
		}
	}
}







# ==============================================================================


=head2 Search( ... )

=over

C<@results = $index-E<gt>Search( \%point, \%options );>

C<$results = $index-E<gt>Search( \%point, \%options );>

Search index for points near a given point

B<C<%point>>

=over

The point to search near

This is either a reference to a hash containing at a minimum a C<lat> and a 
C<lon> value (both in degrees) or a reference to an array giving the point.  
See the B<L<Points|/POINTS>> section above for details.

=back

B<C<%options>>

=over

The parameters for the search (all are optional):

Note that except for C<radius>, none of the below options have any effect when 
C<quick_results> is specified.

B<C<radius>>

=over

Only return results within this distance (in meters) from search point.

If no C<radius> is specified or the C<radius> is set to C<Geo::Index::ALL> then 
all points in the index will be returned.

When C<quick_results> is specified then all points within the specified 
radius will be returned (additional points outside the radius may also 
be returned).

=back

B<C<sort_results>>

=over

Sort results by distance from search point before filtering and returning them.

=back

B<C<max_results>>

=over

Return at most this many results.

Unless sorting is also requested these are not guaranteed to be the closest 
results to the search point.

=back

B<C<pre_condition>>

=over

Reference to additional user-supplied code to determine whether each point 
should be included in the results.

This code is run before the distance from the search point to the result point 
has been calculated.

See the B<L<Condition functions|/CONDITION FUNCTIONS>> section below for syntax.

=back

B<C<post_condition>>

=over

Reference to additional user-supplied code to determine whether each point 
should be included in the results.

This code is run after the distance from the search point to the result point 
has been calculated.

See the B<L<Condition functions|/CONDITION FUNCTIONS>> section below for syntax.

=back

B<C<user_data>>

=over

Arbitrary user-supplied data that is passed to the condition functions.

This can be used to allow the function access to additional data structures.

See the B<L<Condition functions|/CONDITION FUNCTIONS>> section below for syntax.

=back

B<C<quick_results>>

=over

Return the raw preliminary results.  (no result filtering is done)

Normally when a search is performed the raw results have their distances 
computed and are filtered against the search radius and the condition functions.  
This process can be very slow when there are large numbers of points in a result 
set.  Specifying this option skips those steps and can make searches several 
orders of magnitude faster.

When this option is active then instead of returning a list of points the 
C<Search(...)> method will return a list of lists of points (some of which 
may be C<undef>).  If a C<radius> was specified then the results returned will 
contain all the points within that radius.  Additional points outside of the 
search radius will likely be returned as well.

When iterating over the arrays be sure to check whether a list element is C<undef> 
before trying to deference it.

An example of returned quick results (in scalar context); B<L<POINTs|/POINTS>> are references 
to different points:

C<[ [ POINT, POINT, POINT ], [ POINT, POINT ], undef, [ POINT, POINT ] ]>

To be clear, when this option is active rough radius limiting is done but there 
is no filtering done, no distances are computed, and no sorting is performed.

See the B<L<Performance|/PERFORMANCE>> section below for a discussion of this option and when 
to S<use it>.

=back

B<C<tile_adjust>>

=over

Manual adjustment for tile size (signed integer, default is C<0>)
                 
Values C<E<lt> 0> use smaller tiles, values C<E<gt> 0> use larger tiles.  Each 
increment of C<1> doubles or halves the tile size used.  For example, set to 
C<-1> to use tiles half the normal size in each direction.

This option can be a bit counter-intuitive.  Although using smaller tiles will 
result in fewer points that need to be checked or returned it will also lead to
a larger number of tiles that need to be processed.  This can slow things down 
under some circumstances.  Similarly using larger tiles results in more points 
spread over fewer tiles.   What adjustment (if any) will result in the highest 
performance is highly dependant on both the search radius and on the number and 
distribution of the indexed points.  If you adjust this value be sure to 
benchmark your application using a real dataset and the parameters (both typical 
and worst-case) that you expect to use.

=back

=back

B<Return value>

=over

In list context the return value is a list of references to the points found or 
an empty array if none were found.

In scalar context the return value is a reference to the aforementioned list or 
C<undef> if no results were found.

If either the C<sort_results> or C<radius> options were specified in the 
search options then for each point in the results the distance in meters from 
it to the search point will be stored in the C<search_result_distance> entry 
in the result point's hash.  It can be retrieved using e.g. 
S<C<$meters = $$point{search_result_distance};>>

See above section for the results returned when the C<quick_results> option is 
active.

=back

=back

=cut


sub Search($$;$) {
	my ($self, $_search_point, $_options) = @_;
	
	my $_points = $$self{index};
	
	if (ref $_search_point eq 'ARRAY') {
		#. Got array; expand arguments into a full point
		my $lat = $$_search_point[0];
		my $lon = $$_search_point[1];
		
		$_search_point = { 'lat'=>$lat, 'lon'=>$lon };
	}
	
	my $p_lat = $$_search_point{lat};
	my $p_lon = $$_search_point{lon};
	
	#. Search options; user should omit (or set to undef) inactive options:
	
	my $pre_condition  = $$_options{pre_condition};   #. Reference to subroutine returning true if current point should be considered as
	                                                  #. a possible result, false otherwise. This subroutine should not modify any data.
	                                                  #. This subroutine is called before the distance from the search point to the     
	                                                  #. result point has been calculated.                                              
	                                                  #.                                                                                
	my $post_condition = $$_options{post_condition};  #. Reference to subroutine returning true if current point should be considered as
	                                                  #. a possible result, false otherwise. This subroutine should not modify any data.
	                                                  #. This subroutine is called after the distance from the search point to the      
	                                                  #. result point has been calculated.                                              
	                                                  #.                                                                                
	#                    $$_options{user_data};       #. User-defined data that is passed on to the condition subroutine.               
	                                                  #.                                                                                
	my $search_radius  = $$_options{radius};          #. Only points within radius (in meters) will be considered.                      
	                                                  #.                                                                                
	#                    $$_options{sort_results};    #. Sort results by distance from point.                                           
	                                                  #.                                                                                
	my $max_results    = $$_options{max_results};     #. Return at most this many results.                                              
	                                                  #.                                                                                
	my $quick_results  = $$_options{quick_results};   #. Return preliminary results only.  Do not compute distances or call the         
	                                                  #. condition subroutines.  Format returned is either a list of lists of points or 
	                                                  #. a reference to a list of list of points (depending on how Search was called).  
	                                                  #.                                                                                
	my $tile_adjust    = $$_options{tile_adjust};     #. Manual adjustment for tile size (signed integer, default is 0)                 
	                                                  #. Values <0 use smaller tiles, values >0 use larger tiles.                       
	                                                  #. Each increment of 1 doubles or halves the tile size used.                      
	                                                  #. For example, set to -1 to use tiles half the normal size in each direction.    
	                                                  #.                                                                                
	                                                  #. This option can be a bit counter-intuitive.  Although using smaller tiles will 
	                                                  #. result in fewer points that need to be checked or returned it will also lead to
	                                                  #. a larger number of tiles that need to be processed.  This can slow things down 
	                                                  #. under some circumstances.  Similarly using larger tiles results in more points 
	                                                  #. spread over fewer tiles.   What adjustment (if any) will result in the highest 
	                                                  #. performance is highly dependant on both the search radius and on the number    
	                                                  #. and distribution of the indexed points.  If you adjust this value be sure to   
	                                                  #. benchmark your application using a real dataset and the parameters (both 
	                                                  #. typical and worst-case) that you expect to use.                          
	
	$tile_adjust = ( defined $tile_adjust ) ? int $tile_adjust : 0;
	
	$quick_results = (defined $quick_results) ? 1 : 0;
	
	$search_radius = ALL unless defined ($search_radius);
	
	my $_results = [ ];
	my @result_set = ();
	
	my $p_lat_rad;
	if (defined $$_search_point{lat_rad}) {
		$p_lat_rad = $$_search_point{lat_rad};
	} else {
		$p_lat_rad = Math::Trig::deg2rad($p_lat);
		$$_search_point{lat_rad} = $p_lat_rad;
	}
	
	my $p_lon_rad;
	if (defined $$_search_point{lon_rad}) {
		$p_lon_rad = $$_search_point{lon_rad};
	} else {
		$p_lon_rad = Math::Trig::deg2rad($p_lon);
		$$_search_point{lon_rad} = $p_lon_rad;
	}
	
	#. Variables used while computing area extrema
	my $max_size  = $self->{max_size};
	my $max_level = $self->{max_level};
	#. Set earlier: $p_lat, $p_lon, $self->{polar_circumference}, $search_radius
	
	#. Variables set/used while computing area extrema, used to select sets
	my $grid_level;   #. Grid level to pull results from
	my $grid_size;    #. Width or height of grid at chosen grid level
	my $max_grid_idx; #. Highest index in grid at chosen grid level
	my $lat_0_idx;    #. Western extreme of search area (as grid index)
	my $lat_1_idx;    #. Eastern extreme of search area (as grid index)
	my $lon_0_idx;    #. Southern extreme of search area (as grid index)
	my $lon_1_idx;    #. Northern extreme of search area (as grid index)
	
	if (
	     ( $search_radius == ALL ) ||                                  #. Explictly asked to search all points
	     ( $search_radius > $self->{equatorial_circumference} / 4.0 )  #. A search radius over half the globe will search all points
	   ) {
		#. Over half the globe covered by search so search all points
		#. Distances will be calculated but not checked
		
		#. KEY: [ ALL, ALL, ALL ]
		
		if (USE_NUMERIC_KEYS) {
			my $key;
			if (USE_PACKED_KEYS) {
				$key = pack("Q", ( MASK_LEVEL << 58 ) | ( MASK_LATLON << 29 ) | MASK_LATLON );
			} else {
				$key = ( MASK_LEVEL << 58 ) | ( MASK_LATLON << 29 ) | MASK_LATLON;
			}
			push @result_set, $$_points{$key};
			
		} else {
			#. Use split keys
			
			my $key = [ ALL, ALL, ALL ]; #. All points in the world get this index
			push @result_set, $self->GetValue($key);
		}
		
	} else {
		#. Less than half the globe being searched
		
		if ( $C_CODE_ACTIVE ) { # *** C ***
			#. The C code performs the same steps as the Perl version
			
			#. Dummy function that gets replace with the appropriate
			#. C version using either floats or doubles.
			sub ComputeAreaExtrema( $$$$$$$$ ) { }
			
			( $grid_level, $grid_size, $max_grid_idx, $lat_0_idx, $lat_1_idx, $lon_0_idx, $lon_1_idx ) = ComputeAreaExtrema( $tile_adjust, $max_size, $max_level, $p_lat, $p_lat_rad, $p_lon, $self->{polar_circumference}, $search_radius );
			
		} else { # *** Perl ***
			# .--------------------------------------------.
			# | If you change code in this section be sure |
			# | to also update the C version of the code.  |
			# '--------------------------------------------'
			
			#. Get search position in integer form
			my ($p_lat_int, $p_lon_int) = $self->GetIntLatLon($p_lat, $p_lon);
			
			#. Only return points within radius
			
			#. Determine grid level to search at
			
			#. Circumferences at this point (in meters)
			my $NS_circumference_in_meters = $self->{polar_circumference};
			
			#. Size of most detailed grid tile at this point (in meters)
			#. Distance is divided by two to get pole-to-pole distance
			my $ns_indexed_meters = ( $NS_circumference_in_meters / 2.0 ) / $max_size;
			
			#. The north-south size (in meters) of a grid tile is always 
			#. larger than the east-west size (equal at the equator).
			#.
			#. Determine which levels tiles are larger than the search radius
			#.
			#. $search_radius / $ns_indexed_meters
			#.   -> number of most detailed grid tiles at search radius
			#.
			#. ceil( log2( $search_radius / $ns_indexed_meters ) )
			#.   -> relative grid level of tile no larger than search radius
			#.
			#. fast_log2 efficiently performs ceil( log2( n ) ); in C it calls those 
			#. functions directly but a different method is used in the Perl code.
			my $shift = fast_log2( $search_radius / $ns_indexed_meters );
			
			#. Use a slightly higher-resolution grid
			#. We're betting that the time saved by searching a smaller physical area
			#. will outweigh the time needed for the additional index lookups
			#. In practice, this benchmarked over 40% slower than with no adjustment
			#$shift--;
			
			$shift += $tile_adjust;
			
			#. Use a slightly lower-resolution grid
			#. We're betting that the time saved by having to make fewer index lookups 
			#. will outweigh the cost of having to search a larger physical area
			#.
			#. Using a lower resolution speeds things up when searching a small area
			#. (e.g. < 1 km radius at 1M random points) but makes things much slower 
			#. when searching a large radius (e.g. > 10 km radius at 1M random points).
			#$shift += 3;
			
			#. Make sure the shift we computed lies within the index levels
			if ($shift < 0) {
				$shift = 0;
			} elsif ($shift >= $max_level) {	
				$shift = $max_level - 1;
			}
			
			#. Shift is relative to the highest-resolution zoom level
			
			#. Determine grid level to use
			$grid_level = $max_level - $shift;
			
			$grid_size = 2**( $grid_level + 1 );
			$max_grid_idx = $grid_size - 1;
			
			
			#. Determine which grid tiles need to be checked
			
			
			#. Get search point's grid indices
			
			#. Determine number of degrees in one north-south meter
			my $lat_meter_in_degrees = 360.0 / $NS_circumference_in_meters;
			
			#. Searches are performed using angles (degrees or radians) for the radii, not meters
			
			#. Get north-south search radius
			my $lat_radius = $search_radius * $lat_meter_in_degrees;
			my $lat_radius_rad = deg2rad( $lat_radius );
			
			#. Get east-west search radius
			#. This is done as follows:
			#.   o A point is placed on the equator at lat_radius east longitude.
			#.   o Keeping the distance in meters from the the point to the prime 
			#.     meridian constant, the point is rotated north to the search point's 
			#.     latitude.  The point's longitude will move east as this is done.
			#.   o The point's new longitude is measured and this value is used for the 
			#.     lon_radius (east-west search radius).
			my $lon_radius = rad2deg( atan2( sin($lat_radius_rad), cos($lat_radius_rad) * cos($p_lat_rad) ) );
			
			#. The search radii have now been determined
			
			#. Determine the extreme latitudes and longitudes of the search circle
			
			my $lat_0 = $p_lat - $lat_radius;
			my $lat_1 = $p_lat + $lat_radius;
			
			my $lon_0 = $p_lon - $lon_radius;
			my $lon_1 = $p_lon + $lon_radius;
			
			if    ( $lon_0 < -180.0 ) { $lon_0 += 360.0; }
			elsif ( $lon_0 > 180.0 )  { $lon_0 -= 360.0; }
			
			if    ( $lon_1 < -180.0 ) { $lon_1 += 360.0; }
			elsif ( $lon_1 > 180.0 )  { $lon_1 -= 360.0; }
			
			if    ( $lat_0 < -90.0 ) { $lat_0 = -90.0; }
			elsif ( $lat_0 >  90.0 ) { $lat_0 =  90.0; }
			
			if    ( $lat_1 < -90.0 ) { $lat_1 = -90.0; }
			elsif ( $lat_1 >  90.0 ) { $lat_1 =  90.0; }
			
			#. Determine the grid indices for the search circle's extremes
			
			#. Inlined for speed:
			# $lat_0_idx = $self->GetIntLat($lat_0) >> $shift;
			# $lat_1_idx = $self->GetIntLat($lat_1) >> $shift;
			# 
			# $lon_0_idx = $self->GetIntLon($lon_0) >> $shift;
			# $lon_1_idx = $self->GetIntLon($lon_1) >> $shift;
			
			$lat_0_idx = int( ( $lat_0 + 90.0 )  * $max_size / 180.0 );
			$lat_0_idx = $max_size - 1 if ($lat_0_idx >= $max_size);
			$lat_0_idx >>= $shift;
			
			$lat_1_idx = int( ( $lat_1 + 90.0 )  * $max_size / 180.0 );
			$lat_1_idx = $max_size - 1 if ($lat_1_idx >= $max_size);
			$lat_1_idx >>= $shift;
			
			$lon_0_idx = ( int( ( $lon_0 + 180.0 ) * $max_size / 360.0 ) % $max_size ) >> $shift;
			
			$lon_1_idx = ( int( ( $lon_1 + 180.0 ) * $max_size / 360.0 ) % $max_size ) >> $shift;
			#. END inline
			
			#. Make sure latitudes are ordered south then north
			#. (this is not always the case in polar regions)
			#. Longitudes can be in either order to allow straddling of antimeridian
			($lat_0_idx, $lat_1_idx) = ($lat_1_idx, $lat_0_idx) if ($lat_0_idx > $lat_1_idx);
		} # END Perl
		
		#. Grid extrema have now been determined
		
		#. Gather preliminary search results
		
		if (USE_NUMERIC_KEYS) {
			my $seen_n_polar = 0;
			my $seen_s_polar = 0;
			if ($lon_0_idx <= $lon_1_idx) {
				#. Does not straddle antimeridian
				for (my $lat_idx = $lat_0_idx; $lat_idx <= $lat_1_idx; $lat_idx++) {
				
					if ( $lat_idx == 0 ) {
						#. Near south pole
						unless ( $seen_s_polar ) {
							$seen_s_polar = 1;
							my $key;
							if (USE_PACKED_KEYS) {
								$key = pack("Q", ( $grid_level << 58 ) | ( $lat_idx << 29 ) | MASK_LATLON  );
							} else {
								$key = ( $grid_level << 58 ) | ( $lat_idx << 29 ) | MASK_LATLON ;
							}
							push @result_set, $$_points{$key};
						}
						
					} elsif ( $lat_idx >= $max_grid_idx ) {
						#. Near north pole
						unless ( $seen_n_polar ) {
							$seen_n_polar = 1;
							my $key;
							if (USE_PACKED_KEYS) {
								$key = pack("Q", ( $grid_level << 58 ) | ( $lat_idx << 29 ) | MASK_LATLON  );
							} else {
								$key = ( $grid_level << 58 ) | ( $lat_idx << 29 ) | MASK_LATLON ;
							}
							push @result_set, $$_points{$key};
						}
						
					} else {
						#. Normal case
						for (my $lon_idx = $lon_0_idx; $lon_idx <= $lon_1_idx; $lon_idx++) {
							my $clipped_lon_idx = $lon_idx % $grid_size;
							my $key;
							if (USE_PACKED_KEYS) {
								$key = pack("Q", ( $grid_level << 58 ) | ( $lat_idx << 29 ) | $clipped_lon_idx  );
							} else {
								$key = ( $grid_level << 58 ) | ( $lat_idx << 29 ) | $clipped_lon_idx ;
							}
							push @result_set, $$_points{$key};
						}
					}
					
				}
				# END does not straddle antimeridian
				
			} else { # ($lon_0_idx > $lon_1_idx)
				#. Straddles antimeridian
				for (my $lat_idx = $lat_0_idx; $lat_idx <= $lat_1_idx; $lat_idx++) {
					
					if ( $lat_idx == 0 ) {
						#. Near south pole
						unless ( $seen_s_polar ) {
							$seen_s_polar = 1;
							my $key;
							if (USE_PACKED_KEYS) {
								$key = pack("Q", ( $grid_level << 58 ) | ( $lat_idx << 29 ) | MASK_LATLON  );
							} else {
								$key = ( $grid_level << 58 ) | ( $lat_idx << 29 ) | MASK_LATLON ;
							}
							push @result_set, $$_points{$key};
						}
						
					} elsif ( $lat_idx >= $max_grid_idx ) {
						#. Near north pole
						unless ( $seen_n_polar ) {
							$seen_n_polar = 1;
							my $key;
							if (USE_PACKED_KEYS) {
								$key = pack("Q", ( $grid_level << 58 ) | ( $lat_idx << 29 ) | MASK_LATLON  );
							} else {
								$key = ( $grid_level << 58 ) | ( $lat_idx << 29 ) | MASK_LATLON ;
							}
							push @result_set, $$_points{$key};
						}
						
					} else {
						#. Non-polar
						
						#. East side
						for (my $lon_idx = $lon_0_idx; $lon_idx <= $max_grid_idx; $lon_idx++) {
							my $clipped_lon_idx = $lon_idx % $grid_size;
							my $key;
							if (USE_PACKED_KEYS) {
								$key = pack("Q", ( $grid_level << 58 ) | ( $lat_idx << 29 ) | $clipped_lon_idx  );
							} else {
								$key = ( $grid_level << 58 ) | ( $lat_idx << 29 ) | $clipped_lon_idx ;
							}
							push @result_set, $$_points{$key};
						}
						
						#. West side
						for (my $lon_idx = 0; $lon_idx <= $lon_1_idx; $lon_idx++) {
							my $clipped_lon_idx = $lon_idx % $grid_size;
							my $key;
							if (USE_PACKED_KEYS) {
								$key = pack("Q", ( $grid_level << 58 ) | ( $lat_idx << 29 ) | $clipped_lon_idx  );
							} else {
								$key = ( $grid_level << 58 ) | ( $lat_idx << 29 ) | $clipped_lon_idx ;
							}
							push @result_set, $$_points{$key};
						}
					}
				}
			}
		
		} else {
			#. Use split keys
			
			my $seen_n_polar = 0;
			my $seen_s_polar = 0;
			if ($lon_0_idx <= $lon_1_idx) {
				#. Does not straddle antimeridian
				for (my $lat_idx = $lat_0_idx; $lat_idx <= $lat_1_idx; $lat_idx++) {
				
					if ( $lat_idx == 0 ) {
						#. Near south pole
						unless ( $seen_s_polar ) {
							$seen_s_polar = 1;
							my $key = [ $grid_level, $lat_idx, ALL ];
							push @result_set, $self->GetValue($key);
						}
						
					} elsif ( $lat_idx >= $max_grid_idx ) {
						#. Near north pole
						unless ( $seen_n_polar ) {
							$seen_n_polar = 1;
							my $key = [ $grid_level, $lat_idx, ALL ];
							push @result_set, $self->GetValue($key);
						}
						
					} else {
						#. Normal case
						for (my $lon_idx = $lon_0_idx; $lon_idx <= $lon_1_idx; $lon_idx++) {
							my $clipped_lon_idx = $lon_idx % $grid_size;
							my $key = [ $grid_level, $lat_idx, $clipped_lon_idx ];
							push @result_set, $self->GetValue($key);
						}
					}
					
				}
				# END does not straddle antimeridian
				
			} else { # ($lon_0_idx > $lon_1_idx)
				#. Straddles antimeridian
				for (my $lat_idx = $lat_0_idx; $lat_idx <= $lat_1_idx; $lat_idx++) {
					
					if ( $lat_idx == 0 ) {
						#. Near south pole
						unless ( $seen_s_polar ) {
							$seen_s_polar = 1;
							my $key = [ $grid_level, $lat_idx, ALL ];
							push @result_set, $self->GetValue($key);
						}
						
					} elsif ( $lat_idx >= $max_grid_idx ) {
						#. Near north pole
						unless ( $seen_n_polar ) {
							$seen_n_polar = 1;
							my $key = [ $grid_level, $lat_idx, ALL ];
							push @result_set, $self->GetValue($key);
						}
						
					} else {
						#. Non-polar
						
						#. East side
						for (my $lon_idx = $lon_0_idx; $lon_idx <= $max_grid_idx; $lon_idx++) {
							my $clipped_lon_idx = $lon_idx % $grid_size;
							my $key = [ $grid_level, $lat_idx, $clipped_lon_idx ];
							push @result_set, $self->GetValue($key);
						}
						
						#. West side
						for (my $lon_idx = 0; $lon_idx <= $lon_1_idx; $lon_idx++) {
							my $clipped_lon_idx = $lon_idx % $grid_size;
							my $key = [ $grid_level, $lat_idx, $clipped_lon_idx ];
							push @result_set, $self->GetValue($key);
						}
					}
				}
			}
		
		}
	
	}
	
	if ( $quick_results ) {
		#. Return preliminary results
		#. Format is a list of lists (some of which may be undef
		#. All points within the search radius will be returned 
		#. possibly along with additional points outside the 
		#. search radius.
		return ( wantarray )
		       #. Return array:
		       ? @result_set
		       #. Return array reference:
		       : \@result_set;
	}
	
	
	#. Gather results
	
	#. Prepare to compute result distances
	
	SetUpDistance($self->{planetary_diameter}, $p_lat_rad, $p_lon_rad);
	
	if ( $search_radius > 0 ) {
		#. Search for points within radius
		
		if (defined $pre_condition || defined $post_condition) {
			#. Filter specified
			my $user_data      = $$_options{user_data};   #. User-defined data that is passed on to the condition subroutine.
			
			if (defined $pre_condition) {
				if (defined $post_condition) {
					#. Both pre- and post-distance calculation condition
					foreach my $_set ( @result_set ) {
						next unless (defined $_set);
						foreach my $_point (@$_set) {
							if ( &$pre_condition($_point, $_search_point, $user_data) ) {
								my $distance = HaversineDistance($$_point{lat_rad}, $$_point{lon_rad});
								if ( $distance <= $search_radius ) {
									$$_point{search_result_distance} = $distance;
									if ( &$post_condition($_point, $_search_point, $user_data) ) {
										push @$_results, $_point;
									}
								}
							}
						}
					}
				} else {
					#. Only pre-distance calculation condition
					foreach my $_set ( @result_set ) {
						next unless (defined $_set);
						foreach my $_point (@$_set) {
							if ( &$pre_condition($_point, $_search_point, $user_data) ) {
								my $distance = HaversineDistance($$_point{lat_rad}, $$_point{lon_rad});
								if ( $distance <= $search_radius ) {
									$$_point{search_result_distance} = $distance;
									push @$_results, $_point;
								}
							}
						}
					}
				}
			} else {
				#. Only post-distance calculation condition
				foreach my $_set ( @result_set ) {
					next unless (defined $_set);
					foreach my $_point (@$_set) {
						my $distance = HaversineDistance($$_point{lat_rad}, $$_point{lon_rad});
						if ( $distance <= $search_radius ) {
							$$_point{search_result_distance} = $distance;
							if ( &$post_condition($_point, $_search_point, $user_data) ) {
								push @$_results, $_point;
							}
						}
					}
				}
			}
			
			# END conditions present
			
		} else {
			#. No filter
			foreach my $_set ( @result_set ) {
				next unless (defined $_set);
				foreach my $_point (@$_set) {
					my $distance = HaversineDistance($$_point{lat_rad}, $$_point{lon_rad});
					if ( $distance <= $search_radius ) {
						$$_point{search_result_distance} = $distance;
						push @$_results, $_point;
					}
				}
			}
		}
		
	} else {
		#. Explictly asked to search all points
		#. Distances will be calculated but not checked
		
		if (defined $pre_condition || defined $post_condition) {
			#. Filter specified
			my $user_data      = $$_options{user_data};       #. User-defined data that is passed on to the condition subroutine.
			
			if (defined $pre_condition) {
				if (defined $post_condition) {
					#. Both pre- and post-distance calculation condition
					foreach my $_set ( @result_set ) {
						next unless (defined $_set);
						foreach my $_point (@$_set) {
							if ( &$pre_condition($_point, $_search_point, $user_data) ) {
								my $distance = HaversineDistance($$_point{lat_rad}, $$_point{lon_rad});
								$$_point{search_result_distance} = $distance;
								if ( &$post_condition($_point, $_search_point, $user_data) ) {
									push @$_results, $_point;
								}
							}
						}
					}
				} else {
					#. Only pre-distance calculation condition
					foreach my $_set ( @result_set ) {
						next unless (defined $_set);
						foreach my $_point (@$_set) {
							if ( &$pre_condition($_point, $_search_point, $user_data) ) {
								my $distance = HaversineDistance($$_point{lat_rad}, $$_point{lon_rad});
								$$_point{search_result_distance} = $distance;
								push @$_results, $_point;
							}
						}
					}
				}
			} else {
				#. Only post-distance calculation condition
				foreach my $_set ( @result_set ) {
					next unless (defined $_set);
					foreach my $_point (@$_set) {
						my $distance = HaversineDistance($$_point{lat_rad}, $$_point{lon_rad});
						$$_point{search_result_distance} = $distance;
						if ( &$post_condition($_point, $_search_point, $user_data) ) {
							push @$_results, $_point;
						}
					}
				}
			}
			
			# END conditions present
			
		} else {
			#. No filter
			foreach my $_set ( @result_set ) {
				next unless (defined $_set);
				foreach my $_point (@$_set) {
					my $distance = HaversineDistance($$_point{lat_rad}, $$_point{lon_rad});
					$$_point{search_result_distance} = $distance;
					push @$_results, $_point;
				}
			}
		}
	}
	
	if (defined $$_options{sort_results}) {
		#. Return points sorted by distance
		my $_tmp = $_results;  $_results = undef;
		@$_results = sort { $$a{search_result_distance} <=> $$b{search_result_distance} } @$_tmp;
	}
	
	if ( $max_results ) {
		my $result_count = scalar @$_results;
		$max_results = $result_count if ($result_count < $max_results);
	}
	
	return ( wantarray )
	       #. Return array:
	       ? ( scalar @$_results )
	         ? ( $max_results )
	           ? ( scalar @$_results > $max_results ) 
	             ? @$_results[0..($max_results-1)]
	             : @$_results
	           : @$_results
	         : ()
	       #. Return array reference:
	       : ( scalar @$_results )
	         ? ( $max_results )
	           ? ( scalar @$_results > $max_results ) 
	             ? [ @$_results[0..($max_results-1)] ]
	             : $_results
	           : $_results
	         : undef; #. undef == No result found
}









# ==============================================================================


=head2 SearchByBounds( ... )

=over

C<@results = $index-E<gt>SearchByBounds( \@bounds, \%options );>

C<@results = $index-E<gt>SearchByBounds( \%bounds, \%options );>

C<$results = $index-E<gt>SearchByBounds( \@bounds, \%options );>

C<$results = $index-E<gt>SearchByBounds( \%bounds, \%options );>

Search index for points within a given bounding box

The points returned are those that lie between the specified latitudes and 
longitudes.  The four corners form a rectangle only when using certain map 
projections such as L<equirectangular|https://en.wikipedia.org/wiki/Equirectangular_projection> 
or L<mercator|https://en.wikipedia.org/wiki/Mercator_projection> 
(including L<pseudo-mercator|https://en.wikipedia.org/wiki/Web_Mercator_projection> 
a.k.a. web mercator as used by slippy maps).  If you are using a projection 
that does not have horizontal lines of latitude and vertical lines of longitude 
and you want the results to lie within and/or fill a rectangle on your map then 
your code will need to perform the appropriate bounds adjustment and point 
filtering itself.

B<C<@bounds>> or B<C<%bounds>>

=over

The search boundaries

This can be specified either as a list or a hash.  Any of the following are 
acceptable:

=over

C<( I<w_val>, I<s_val>, I<e_val>, I<n_val> )>

C<( 'south' =E<gt> I<s_val>, 'north' =E<gt> I<n_val>, 'west' =E<gt> I<w_val>, 'east' =E<gt> I<e_val> )>

C<( 's' =E<gt> I<s_val>, 'n' =E<gt> I<n_val>, 'w' =E<gt> I<w_val>, 'e' =E<gt> I<e_val> )>

C<( 'S' =E<gt> I<s_val>, 'N' =E<gt> I<n_val>, 'W' =E<gt> I<w_val>, 'E' =E<gt> I<e_val> )>

=back

C<I<s_val>> and C<I<n_val>> are the south and north latitudes of the bounding 
box and C<I<w_val>> and C<I<e_val>> are its west and east longitudes (all values 
are in degrees).  For the list form the order matches that used by PostGIS, 
shapefiles, and GeoJSON but be aware that the order of the fields is not 
standardized.

=back

B<C<%options>>

=over

The parameters for the search (all are optional):

Note that none of the below options have any effect when C<quick_results> is 
specified.

=over

B<C<max_results>>

=over

Return at most this many results.

=back

B<C<condition>>

=over

Reference to additional user-supplied code to determine whether each point 
should be included in the results.

Note that unlike with the other search methods there is only a single condition 
function.  Instead of the C<$_search_point>, the second parameter to the 
condition function is a reference to the bounding box in list form (as described 
above for C<@bounds>).  Lastly, since "distance from search point" makes no 
sense in the context of a bounding box, none is provided to the function.

See the B<L<Condition functions|/CONDITION FUNCTIONS>> section below for syntax.

=back

B<C<user_data>>

=over

Arbitrary user-supplied data that is passed to the condition function.

This can be used to allow the function access to additional data structures.

See the B<L<Condition functions|/CONDITION FUNCTIONS>> section below for syntax.

=back

B<C<quick_results>>

=over

Return the raw preliminary results.  (no result filtering is done)

Normally when a search is performed the raw results are filtered to ensure that 
they lie within the bounds and the condition function is applied to each result 
point.  This process can be slow when there are large numbers of points in a 
result set.  Specifying this option skips those steps and can make searches 
faster.

When this option is active then instead of returning a list of points the 
C<SearchByBounds(...)> method will return a list of lists of points (some 
of which may be C<undef>).  The results are guaranteed to contain all points 
within the requested bounds but additional points outside of the requested 
bounds will likely be returned as well.

When iterating over the arrays be sure to check whether a list element is C<undef> 
before trying to deference it.

An example of returned quick results (in scalar context); B<L<POINTs|/POINTS>> are references 
to different points:

C<[ [ POINT, POINT, POINT ], [ POINT, POINT ], undef, [ POINT, POINT ] ]>

To be clear, when this option is active rough bounds limiting is done but there 
is no filtering done and no bound checks are actually performed.

See the B<L<Performance|/PERFORMANCE>> section below for a discussion of this 
option and when to use it.

=back


B<C<tile_adjust>>

=over

Manual adjustment for tile size (signed integer, default is C<0>)

Values C<E<lt> 0> use smaller tiles, values C<E<gt> 0> use larger tiles.  Each
increment of C<1> doubles or halves the tile size used.  For example, set to
C<-1> to use tiles half the normal size in each direction.

This option can be a bit counter-intuitive.  Although using smaller tiles will
result in fewer points that need to be checked or returned it will also lead to
a larger number of tiles that need to be processed.  This can slow things down
under some circumstances.  Similarly using larger tiles results in more points
spread over fewer tiles.   What adjustment (if any) will result in the highest 
performance is highly dependant on both the search radius and on the number and 
distribution of the indexed points.  If you adjust this value be sure to 
benchmark your application using a real dataset and the parameters (both typical 
and worst-case) that you expect to use.

=back

=back

B<Return value>

=over

In list context the return value is a list of references to the points found or 
an empty array if none were found.

In scalar context the return value is a reference to the aforementioned list or 
C<undef> if no results were found.

See above section for the results returned when the C<quick_results> option is 
active.

=back

=back

=back

=cut


use constant TRACE_BOUNDS => 0;  # Uncomment for no tracing of this method
#use constant TRACE_BOUNDS => 1;  # Uncomment to enable tracing of this method

sub SearchByBounds($$;$) {
	my ($self, $_bounding_box, $_options) = @_;
	
	my $_points = $$self{index};
	
	#. Determine bounding box
	
	my ( $south, $north, $west, $east );
	
	if (ref $_bounding_box eq 'HASH') {
		#. Got hash; convert bounds to array
		
		$west  = $$_bounding_box{w}     ? $$_bounding_box{w}
		       : $$_bounding_box{W}     ? $$_bounding_box{W}
		       : $$_bounding_box{west}  ? $$_bounding_box{west}
		       : croak "Could not find west value for bounds";
		
		$south = $$_bounding_box{s}     ? $$_bounding_box{s}
		       : $$_bounding_box{S}     ? $$_bounding_box{S}
		       : $$_bounding_box{south} ? $$_bounding_box{south}
		       : croak "Could not find south value for bounds";
		
		$east  = $$_bounding_box{e}     ? $$_bounding_box{e}
		       : $$_bounding_box{E}     ? $$_bounding_box{E}
		       : $$_bounding_box{east}  ? $$_bounding_box{east}
		       : croak "Could not find east value for bounds";
		
		$north = $$_bounding_box{n}     ? $$_bounding_box{n}
		       : $$_bounding_box{N}     ? $$_bounding_box{N}
		       : $$_bounding_box{north} ? $$_bounding_box{north}
		       : croak "Could not find north value for bounds";
		
		$_bounding_box = [ $west, $south, $east, $north ];
		
	} else {
		#. Bounds in array form
		
		$south = $$_bounding_box[1];
		$north = $$_bounding_box[3];
		
		$west = $$_bounding_box[0];
		$east = $$_bounding_box[2];
	}
	
	#. Make sure bounds are valid
	
	my $has_errors = 0;
	
	if ($west < -180.0) {
		carp "In SearchByBounds: west bound $west is out of range ( < -180 )" unless $self->{quiet};
		$has_errors = 1;
	}
	
	if ($east > 180.0) {
		carp "In SearchByBounds: east bound $east is out of range ( > 180 )" unless $self->{quiet};
		$has_errors = 1;
	}
	
	if ($south < -90.0) {
		carp "In SearchByBounds: south bound $south is out of range ( < -90 )" unless $self->{quiet};
		$has_errors = 1;
	}
	
	if ($north > 90.0) {
		carp "In SearchByBounds: north bound $north is out of range ( > 90 )" unless $self->{quiet};
		$has_errors = 1;
	}
	
	if ($south > $north) {
		carp "In SearchByBounds: south bound greater than north bound ( $south > $north )" unless $self->{quiet};
		$has_errors = 1;
	} elsif ($south == $north) {
		carp "In SearchByBounds: bounds cover no area ( south > north: $south > $north )" unless $self->{quiet};
		$has_errors = 1;
	}
	
	if ($has_errors) {
		return (wantarray) ? ( ) : undef;
	}
	
	#. Search options; user should omit (or set to undef) inactive options:
	
	my $condition      = $$_options{condition};       #. Reference to subroutine returning true if current point should be considered as
	                                                  #. a possible result, false otherwise. This subroutine should not modify any data.
	                                                  #. This subroutine is called before the distance from the search point to the     
	                                                  #. result point has been calculated.                                              
	                                                  #.                                                                                
	#                    $$_options{user_data};       #. User-defined data that is passed on to the condition subroutine.               
	                                                  #.                                                                                
	my $max_results    = $$_options{max_results};     #. Return at most this many results.                                              
	                                                  #.                                                                                
	my $quick_results  = $$_options{quick_results};   #. Return preliminary results only.  Do not compute distances or call the         
	                                                  #. condition subroutines.  Format returned is either a list of lists of points or 
	                                                  #. a reference to a list of list of points (depending on how Search was called).  
	                                                  #.                                                                                
	my $tile_adjust    = $$_options{tile_adjust};     #. Manual adjustment for tile size (signed integer, default is 0)                 
	                                                  #. Values <0 use smaller tiles, values >0 use larger tiles.                       
	                                                  #. Each increment of 1 doubles or halves the tile size used.                      
	                                                  #. For example, set to -1 to use tiles half the normal size in each direction.    
	                                                  #.                                                                                
	                                                  #. This option can be a bit counter-intuitive.  Although using smaller tiles will 
	                                                  #. result in fewer points that need to be checked or returned it will also lead to
	                                                  #. a larger number of tiles that need to be processed.  This can slow things down 
	                                                  #. under some circumstances.  Similarly using larger tiles results in more points 
	                                                  #. spread over fewer tiles.   What adjustment (if any) will result in the highest 
	                                                  #. performance is highly dependent on both the search radius and on the number    
	                                                  #. and distribution of the indexed points.  If you adjust this value be sure to   
	                                                  #. benchmark your application using a real dataset and the parameters (both       
	                                                  #. typical and worst-case) that you expect to use.                          
	
	$tile_adjust = ( defined $tile_adjust ) ? int $tile_adjust : 0;
	
	$quick_results = (defined $quick_results) ? 1 : 0;
	
	if ( TRACE_BOUNDS ) {
		print "Bounds:    W: $west, S: $south, E: $east, N: $north\n";
	}
	
	my @keys; #. The index keys to return points from
	if ( TRACE_BOUNDS) {
		@keys = ();
	}
	
	my $_results = [ ];
	my @result_set = ();
	
	my $max_level = $self->{max_level};
	
	#. Variables set/used while computing area extrema, used to select sets
	my $grid_level;   #. Grid level to pull results from
	my $grid_size;    #. Width or height of grid at chosen grid level
	my $max_grid_idx; #. Highest index in grid at chosen grid level
	my $shift;        #. Number of bits to shift integer latitudes and longitudes to yield valid indices at the active grid level
	
	#. Determine how many degrees the bounds cover in each direction
	
	my $lat_degrees = $north - $south;
	if ($lat_degrees <= 0) {
		carp "In SearchByBounds north ($north) is less than or equal to south ($south)!\n" unless $self->{quiet};
		return (wantarray) ? ( ) : undef;
	}
	
	my $lon_degrees = ($west <= $east) ? $east - $west               #. Normal case
	                                   : ( $east + 360.0 ) - $west;  #. Straddles antimeridian
	
	if ( TRACE_BOUNDS) {
		print "my \$lon_degrees = $lon_degrees = ($west <= $east) ? $east - $west : ( $east + 360.0 ) - $west;\n";
	}
	
	#. Determine grid level to use
	
	my $lat_best_level = fast_log2( 180.0 / $lat_degrees );
	my $lon_best_level = fast_log2( 360.0 / $lon_degrees );
	
	$grid_level = ( $lat_best_level > $lon_best_level ) ? $lat_best_level : $lon_best_level;
	$grid_level -= $tile_adjust;
	
	#. Determine shift and grid size for the chosen level
	
	$shift = $max_level - $grid_level;
	
	#$shift += $tile_adjust;
	
	$grid_size = 2**( $grid_level + 1 );
	$max_grid_idx = $grid_size - 1;
	
	#. Compute grid indices for bounds extrema
	
	my ($south_int, $west_int) = $self->GetIntLatLon($south, $west);
	my ($north_int, $east_int) = $self->GetIntLatLon($north, $east);
	
	my $north_idx = $north_int >> $shift;  #. Northern extreme of search area (as grid index)
	my $south_idx = $south_int >> $shift;  #. Southern extreme of search area (as grid index)
	my $east_idx  = $east_int  >> $shift;  #. Eastern extreme of search area (as grid index)
	my $west_idx  = $west_int  >> $shift;  #. Western extreme of search area (as grid index)
	
	$east_idx  = $max_grid_idx if ($east == 180.0);  #. Special case for antimeridian as east bound
	$north_idx = $max_grid_idx if ($north == 90.0);  #. Special case for north pole as north bound
	
	my $include_south_pole = ( $south == -90.0 ) ? 1 : 0;
	my $include_north_pole = ( $north ==  90.0 ) ? 1 : 0;
	
	if ( TRACE_BOUNDS) {
		print "Poles:\tN: $include_north_pole\tS: $include_south_pole\n";
		
		print "Integer:   W: $west_int, S: $south_int, E: $east_int, N: $north_int\n";
		print "Index ($grid_level): W: $west_idx, S: $south_idx, E: $east_idx, N: $north_idx\n";
		print "Shift: $shift\tgrid_size: $grid_size\tmax_grid_idx: $max_grid_idx\n";
		print "---\n\n";
	}
	
	#. Gather preliminary search results
	
	if (USE_NUMERIC_KEYS) {
		my $seen_n_polar = 0;
		my $seen_s_polar = 0;
		if ( $west <= $east ) {
			#. Does not straddle antimeridian
			if ( TRACE_BOUNDS) {
				print "NORMAL\n";
			}
			for (my $lat_idx = $south_idx; $lat_idx <= $north_idx; $lat_idx++) {
				if ( $lat_idx == 0 ) {
					#. Near south pole
					unless ( $seen_s_polar ) {
						$seen_s_polar = 1;
						my $key;
						if (USE_PACKED_KEYS) {
							$key = pack("Q", ( $grid_level << 58 ) | ( $lat_idx << 29 ) | MASK_LATLON  );
						} else {
							$key = ( $grid_level << 58 ) | ( $lat_idx << 29 ) | MASK_LATLON ;
						}
						push @keys, "[ $grid_level, $lat_idx, ALL ]" if ( TRACE_BOUNDS);
						push @result_set, $$_points{$key};
					}
					
				} elsif ( $lat_idx >= $max_grid_idx ) {
					#. Near north pole
					unless ( $seen_n_polar ) {
						$seen_n_polar = 1;
						my $key;
						if (USE_PACKED_KEYS) {
							$key = pack("Q", ( $grid_level << 58 ) | ( $lat_idx << 29 ) | MASK_LATLON  );
						} else {
							$key = ( $grid_level << 58 ) | ( $lat_idx << 29 ) | MASK_LATLON ;
						}
						push @keys, "[ $grid_level, $lat_idx, ALL ]" if ( TRACE_BOUNDS);
						push @result_set, $$_points{$key};
					}
					
				} else {
					#. Normal case
					for (my $lon_idx = $west_idx; $lon_idx <= $east_idx; $lon_idx++) {
						my $clipped_lon_idx = $lon_idx % $grid_size;
						my $key;
						if (USE_PACKED_KEYS) {
							$key = pack("Q", ( $grid_level << 58 ) | ( $lat_idx << 29 ) | $clipped_lon_idx  );
						} else {
							$key = ( $grid_level << 58 ) | ( $lat_idx << 29 ) | $clipped_lon_idx ;
						}
						push @result_set, $$_points{$key};
						push @keys, "[ $grid_level, $lat_idx, $clipped_lon_idx ]" if ( TRACE_BOUNDS);
					}
				}
				
			}
			# END does not straddle antimeridian
			
		} else { # ($west_idx > $east_idx)
			#. Straddles antimeridian
			if ( TRACE_BOUNDS) {
				print "STRADDLES ANTIMERIDIAN\n";
			}
			for (my $lat_idx = $south_idx; $lat_idx <= $north_idx; $lat_idx++) {
				
				if ( $lat_idx == 0 ) {
					#. Near south pole
					unless ( $seen_s_polar ) {
						$seen_s_polar = 1;
						my $key = ( $grid_level << 58 ) | ( $lat_idx << 29 ) | MASK_LATLON ;
						push @result_set, $$_points{$key};
						push @keys, "[ $grid_level, $lat_idx, ALL ]" if ( TRACE_BOUNDS);
					}
					
				} elsif ( $lat_idx >= $max_grid_idx ) {
					#. Near north pole
					unless ( $seen_n_polar ) {
						$seen_n_polar = 1;
						my $key = ( $grid_level << 58 ) | ( $lat_idx << 29 ) | MASK_LATLON ;
						push @result_set, $$_points{$key};
						push @keys, "[ $grid_level, $lat_idx, ALL ]" if ( TRACE_BOUNDS);
					}
					
				} else {
					#. Non-polar
					
					#. East side
					for (my $lon_idx = $west_idx; $lon_idx <= $max_grid_idx; $lon_idx++) {
						my $clipped_lon_idx = $lon_idx % $grid_size;
						my $key = ( $grid_level << 58 ) | ( $lat_idx << 29 ) | $clipped_lon_idx ;
						push @result_set, $$_points{$key};
						push @keys, "[ $grid_level, $lat_idx, $clipped_lon_idx ]" if ( TRACE_BOUNDS);
					}
					
					#. West side
					for (my $lon_idx = 0; $lon_idx < $east_idx; $lon_idx++) {
						my $clipped_lon_idx = $lon_idx % $grid_size;
						my $key = ( $grid_level << 58 ) | ( $lat_idx << 29 ) | $clipped_lon_idx ;
						push @result_set, $$_points{$key};
						push @keys, "[ $grid_level, $lat_idx, $clipped_lon_idx ]" if ( TRACE_BOUNDS);
					}
				}
			}
		} # END straddles antimeridian
	
	} else {
		#. Use split keys
		
		my $seen_n_polar = 0;
		my $seen_s_polar = 0;
		if ($west <= $east) {
			#. Does not straddle antimeridian
			if ( TRACE_BOUNDS) {
				print "NORMAL\n";
			}
			for (my $lat_idx = $south_idx; $lat_idx <= $north_idx; $lat_idx++) {
			
				if ( $lat_idx == 0 ) {
					#. Near south pole
					unless ( $seen_s_polar ) {
						$seen_s_polar = 1;
						my $key = [ $grid_level, $lat_idx, ALL ];
						push @result_set, $self->GetValue($key);
						push @keys, "[ $grid_level, $lat_idx, ALL ]" if ( TRACE_BOUNDS);
					}
					
				} elsif ( $lat_idx >= $max_grid_idx ) {
					#. Near north pole
					unless ( $seen_n_polar ) {
						$seen_n_polar = 1;
						my $key = [ $grid_level, $lat_idx, ALL ];
						push @result_set, $self->GetValue($key);
						push @keys, "[ $grid_level, $lat_idx, ALL ]" if ( TRACE_BOUNDS);
					}
					
				} else {
					#. Normal case
					for (my $lon_idx = $west_idx; $lon_idx <= $east_idx; $lon_idx++) {
						my $clipped_lon_idx = $lon_idx % $grid_size;
						my $key = [ $grid_level, $lat_idx, $clipped_lon_idx  ];
						push @result_set, $self->GetValue($key);
						push @keys, "[ $grid_level, $lat_idx, $clipped_lon_idx ($lon_idx) ]" if ( TRACE_BOUNDS);
					}
				}
				
			}
			# END does not straddle antimeridian
			
		} else {  # ($west_idx > $east_idx)
			#. Straddles antimeridian
			if ( TRACE_BOUNDS) {
				print "STRADDLES ANTIMERIDIAN\n";
			}
			for (my $lat_idx = $south_idx; $lat_idx <= $north_idx; $lat_idx++) {
				
				if ( $lat_idx == 0 ) {
					#. Near south pole
					unless ( $seen_s_polar ) {
						$seen_s_polar = 1;
						my $key = [ $grid_level, $lat_idx, ALL ];
						push @result_set, $self->GetValue($key);
						push @keys, "[ $grid_level, $lat_idx, ALL ]" if ( TRACE_BOUNDS);
					}
					
				} elsif ( $lat_idx >= $max_grid_idx ) {
					#. Near north pole
					unless ( $seen_n_polar ) {
						$seen_n_polar = 1;
						my $key = [ $grid_level, $lat_idx, ALL ];
						push @result_set, $self->GetValue($key);
						push @keys, "[ $grid_level, $lat_idx, ALL ]" if ( TRACE_BOUNDS);
					}
					
				} else {
					#. Non-polar
					
					#. East side
					for (my $lon_idx = $west_idx; $lon_idx <= $max_grid_idx; $lon_idx++) {
						my $clipped_lon_idx = $lon_idx % $grid_size;
						my $key = [ $grid_level, $lat_idx, $clipped_lon_idx ];
						push @result_set, $self->GetValue($key);
						push @keys, "[ $grid_level, $lat_idx, $clipped_lon_idx ($lon_idx, E) ]" if ( TRACE_BOUNDS);
					}
					
					#. West side
					for (my $lon_idx = 0; $lon_idx < $east_idx; $lon_idx++) {
						my $clipped_lon_idx = $lon_idx % $grid_size;
						my $key = [ $grid_level, $lat_idx, $clipped_lon_idx ];
						push @result_set, $self->GetValue($key);
						push @keys, "[ $grid_level, $lat_idx, $clipped_lon_idx ($lon_idx, W) ]" if ( TRACE_BOUNDS);
					}
				}
			}
		} # END straddles antimeridian
	
	} # END using split keys
	
	print join("\n", @keys); print "\n" if ( TRACE_BOUNDS);
	
	if ( $quick_results ) {
		#. Return preliminary results
		#. Format is a list of lists (some of which may be undef
		#. All points within the search radius will be returned 
		#. possibly along with additional points outside the 
		#. search radius.
		return ( wantarray )
		       #. Return array:
		       ? @result_set
		       #. Return array reference:
		       : \@result_set;
	}
	
	
	#. Gather results
	
	if ($west <= $east) {
		#. Normal case
		if ( TRACE_BOUNDS) {
			print "NORMAL\n";
		}
		
		if (defined $condition) {
			#. Filter specified
			my $user_data      = $$_options{user_data};  #. User-defined data that is passed on to the condition subroutine.
			foreach my $_set ( @result_set ) {
				next unless (defined $_set);
				foreach my $_point (@$_set) {
					my $p_lat = $$_point{lat};
					my $p_lon = $$_point{lon};
					
					if ( TRACE_BOUNDS) {
						print "--------------------------------------------------------------------------------\n";
						print "					     ( p_lat:$p_lat >= south:$south ) &&\n";
						print "					     ( p_lat:$p_lat <= north:$north ) &&\n";
						print "					     (\n";
						print "					       ( p_lon:$p_lon >= west:$west ) ||\n";
						print "					       ( p_lon:$p_lon <= east:$east ) ||\n";
						print "						     ( include_south_pole:$include_south_pole && p_lat:$p_lat == -90.0 ) ||\n";
						print "						     ( include_north_pole:$include_north_pole && p_lat:$p_lat == 90.0 )\n";
						print "					     )\n";
						print "--------------------------------------------------------------------------------\n";
					}
					
					if ( 
					     (
					       ( $p_lat >= $south ) &&
					       ( $p_lat <= $north ) &&
					       ( $p_lon >= $west ) &&
					       ( $p_lon <= $east )
					     ) ||
					     ( $include_south_pole && $p_lat == -90.0 ) ||
					     ( $include_north_pole && $p_lat == 90.0 )
					   ) {
						if ( &$condition($_point, $_bounding_box, $user_data) ) {
							push @$_results, $_point;
							print "POINT: $$_point{name}\n" if ( TRACE_BOUNDS);
						} else {
							print "-----: $$_point{name}\n" if ( TRACE_BOUNDS);
						}
					}
				}
			}
		} else {
			#. No filter
			foreach my $_set ( @result_set ) {
				next unless (defined $_set);
				foreach my $_point (@$_set) {
					my $p_lat = $$_point{lat};
					my $p_lon = $$_point{lon};
					
					if ( TRACE_BOUNDS) {
						print "--------------------------------------------------------------------------------\n";
						print "					     ( p_lat:$p_lat >= south:$south ) &&\n";
						print "					     ( p_lat:$p_lat <= north:$north ) &&\n";
						print "					     (\n";
						print "					       ( p_lon:$p_lon >= west:$west ) ||\n";
						print "					       ( p_lon:$p_lon <= east:$east ) ||\n";
						print "						     ( include_south_pole:$include_south_pole && p_lat:$p_lat == -90.0 ) ||\n";
						print "						     ( include_north_pole:$include_north_pole && p_lat:$p_lat == 90.0 )\n";
						print "					     )\n";
						print "--------------------------------------------------------------------------------\n";
					}
					
					if ( 
					     (
					       ( $p_lat >= $south ) &&
					       ( $p_lat <= $north ) &&
					       ( $p_lon >= $west ) &&
					       ( $p_lon <= $east )
					     ) ||
					     ( $include_south_pole && $p_lat == -90.0 ) ||
					     ( $include_north_pole && $p_lat == 90.0 )
					   ) {
						push @$_results, $_point;
						print "POINT: $$_point{name}\n" if ( TRACE_BOUNDS);
					} else {
						print "-----: $$_point{name}\n" if ( TRACE_BOUNDS);
					}
				}
			}
		}
		
	} else {
		#. Straddles antimeridian (west > east)
		if ( TRACE_BOUNDS) {
			print "STRADDLES ANTIMERIDIAN\n";
		}
		
		if (defined $condition) {
			#. Filter specified
			my $user_data      = $$_options{user_data};  #. User-defined data that is passed on to the condition subroutine.
			foreach my $_set ( @result_set ) {
				next unless (defined $_set);
				foreach my $_point (@$_set) {
					my $p_lat = $$_point{lat};
					my $p_lon = $$_point{lon};
					
					if ( TRACE_BOUNDS) {
						print "--------------------------------------------------------------------------------\n";
						print "					     ( p_lat:$p_lat >= south:$south ) &&\n";
						print "					     ( p_lat:$p_lat <= north:$north ) &&\n";
						print "					     (\n";
						print "					       ( p_lon:$p_lon >= west:$west ) ||\n";
						print "					       ( p_lon:$p_lon <= east:$east ) ||\n";
						print "						     ( include_south_pole:$include_south_pole && p_lat:$p_lat == -90.0 ) ||\n";
						print "						     ( include_north_pole:$include_north_pole && p_lat:$p_lat == 90.0 )\n";
						print "					     )\n";
						print "--------------------------------------------------------------------------------\n";
					}
					
					if ( 
					     ( $p_lat >= $south ) &&
					     ( $p_lat <= $north ) &&
					     (
					       ( $p_lon >= $west ) ||
					       ( $p_lon <= $east ) ||
						     ( $include_south_pole && $p_lat == -90.0 ) ||
						     ( $include_north_pole && $p_lat == 90.0 )
					     )
					   ) {
						if ( &$condition($_point, $_bounding_box, $user_data) ) {
							push @$_results, $_point;
							print "POINT: $$_point{name}\n" if ( TRACE_BOUNDS);
						} else {
							print "-----: $$_point{name}\n" if ( TRACE_BOUNDS);
						}
					}
				}
			}
		} else {
			#. No filter
			foreach my $_set ( @result_set ) {
				next unless (defined $_set);
				foreach my $_point (@$_set) {
					my $p_lat = $$_point{lat};
					my $p_lon = $$_point{lon};
					
					if ( TRACE_BOUNDS) {
						print "--------------------------------------------------------------------------------\n";
						print "					     ( p_lat:$p_lat >= south:$south ) &&\n";
						print "					     ( p_lat:$p_lat <= north:$north ) &&\n";
						print "					     (\n";
						print "					       ( p_lon:$p_lon >= west:$west ) ||\n";
						print "					       ( p_lon:$p_lon <= east:$east ) ||\n";
						print "						     ( include_south_pole:$include_south_pole && p_lat:$p_lat == -90.0 ) ||\n";
						print "						     ( include_north_pole:$include_north_pole && p_lat:$p_lat == 90.0 )\n";
						print "					     )\n";
						print "--------------------------------------------------------------------------------\n";
					}
					
					if ( 
					     ( $p_lat >= $south ) &&
					     ( $p_lat <= $north ) &&
					     (
					       ( $p_lon >= $west ) ||
					       ( $p_lon <= $east ) ||
						     ( $include_south_pole && $p_lat == -90.0 ) ||
						     ( $include_north_pole && $p_lat == 90.0 )
					     )
					   ) {
						push @$_results, $_point;
						print "POINT: $$_point{name}\n" if ( TRACE_BOUNDS);
					} else {
						print "-----: $$_point{name}\n" if ( TRACE_BOUNDS);
					}
				}
			}
		}
		
	}
	
	if ( $max_results ) {
		my $results_count = scalar @$_results;
		$max_results = $results_count if ($results_count < $max_results);
	}
	
	return ( wantarray )
	       #. Return array:
	       ? ( scalar @$_results )
	         ? ( $max_results )
	           ? ( scalar @$_results > $max_results ) 
	             ? @$_results[0..($max_results-1)]
	             : @$_results
	           : @$_results
	         : ()
	       #. Return array reference:
	       : ( scalar @$_results )
	         ? ( $max_results )
	           ? ( scalar @$_results > $max_results ) 
	             ? [ @$_results[0..($max_results-1)] ]
	             : $_results
	           : $_results
	         : undef; #. undef == No result found
}


# ==============================================================================











=head2 Closest( ... )

=over

C<@results = $index-E<gt>Closest( \%point, $number_of_points_desired, \%options );>

C<$results = $index-E<gt>Closest( \%point, $number_of_points_desired, \%options );>

Find the point or points closest to a given point

Note that if you want to find the closest points within a given radius it may be 
faster to use C<L<Search(...)|/Search( ... )>> instead.  See the B<L<Performance|/PERFORMANCE>> 
section below for more details.

B<C<%point>>

=over

The point to search near

This is either a reference to a hash containing at a minimum a C<lat> and a 
C<lon> value (both in degrees) or a reference to an array giving the point.  
See the B<L<Points|/POINTS>> section above for details.

=back

B<C<$number_of_points_desired>>

=over

The number of points that should be returned.

Set to C<0> to not restrict the number of points returned or set it S<E<gt> C<0>> 
to set the maximum number of points to return.

If omitted then this will default to C<1>.

=back

B<C<%options>>

=over

The parameters for the search (all are optional):

B<C<radius>>

=over

Only return results within this distance (in meters) from search point.

If no C<radius> is specified or the C<radius> is set to C<Geo::Index::ALL> then 
all points in the index may potentially be returned.

=back

B<C<sort_results>>

=over

Sort results by distance from point

By default points returned are sorted by distance.  Set this to C<0> to not 
sort the returned points.

Although sorting is not mandatory, performing it is strongly recommended since 
otherwise the set of points returned are not guaranteed to be the closest.

=back

B<C<pre_condition>>

=over

Reference to additional user-supplied code to determine whether each point 
should be included in the results.

This code is run before the distance from the search point to the result point 
has been calculated.

See the B<L<Condition functions|/CONDITION FUNCTIONS>> section below for syntax.

=back

B<C<post_condition>>

=over

Reference to additional user-supplied code to determine whether each point 
should be included in the results.

This code is run after the distance from the search point to the result point 
has been calculated.

By default, a C<post_condition> function that filters out the search point 
is used.  To remove this default function either specify a new one or set 
C<post_condition> to "C<NONE>".

See the B<L<Condition functions|/CONDITION FUNCTIONS>> section below for syntax.

=back

B<C<user_data>>

=over

Arbitrary user-supplied data that is passed to the condition functions.

This can be used to allow the function access to additional data structures.

See the B<L<Condition functions|/CONDITION FUNCTIONS>> section below for syntax.

=back

=back

B<Return value>

=over

In list context the return value is a list of references to the points found or 
an empty array if none were found.

In scalar context the return value is a reference to the aforementioned list or 
C<undef> if no results were found.

For each point in the results the distance in meters from it to the search point 
will be stored in the C<search_result_distance> entry in the result point's 
hash.  It can be retrieved using e.g. S<C<$meters = $$point{search_result_distance};>>

=back

=back

=cut



#. Return closest point or points to search point

sub Closest($$;$$) {
	my ($self, $_search_point, $number_of_points_desired, $_options) = @_;
	
	# Allow calling as Closest( POINT, OPTIONS ) when only a single point is desired.
	if (ref $number_of_points_desired) {
		$_options = $number_of_points_desired;
		$number_of_points_desired = 1;
	}
	
	#. Get the point index
	my $_points = $$self{index};
	
	
	if (ref $_search_point eq 'ARRAY') {
		#. Got array; expand arguments into a full point
		my $lat = $$_search_point[0];
		my $lon = $$_search_point[1];
		
		$_search_point = { 'lat'=>$lat, 'lon'=>$lon };
	}
	
	#. Get search point's position
	my $p_lat = $$_search_point{lat};
	my $p_lon = $$_search_point{lon};
	
	#. Search options; user should omit (or set to undef) inactive options:
	
	my $pre_condition  = $$_options{pre_condition};   #. Reference to subroutine returning true if current point should be considered as
	                                                  #. a possible result, false otherwise. This subroutine should not modify any data.
	                                                  #. This subroutine is called before the distance from the search point to the     
	                                                  #. result point has been calculated.                                              
	                                                  #.                                                                                
	my $post_condition = $$_options{post_condition};  #. Reference to subroutine returning true if current point should be considered as
	                                                  #. a possible result, false otherwise. This subroutine should not modify any data.
	                                                  #. This subroutine is called after the distance from the search point to the      
	                                                  #. result point has been calculated.                                              
	                                                  #.                                                                                
	                                                  #. If no post_condition is specified then the default function (given below, omits
	                                                  #. the search point from the results) will be used.  To override this behavior    
	                                                  #. either define your own post_condition function or set post_condition to "NONE".
	                                                  #.                                                                                
	                                                  #. Default post_condition:                                                        
	                                                  #.                                                                                
	                                                  #.     sub {                                                                      
	                                                  #.         my ( $result_point, $search_point, $user_data ) = @_;                  
	                                                  #.         return ( $result_point != $search_point );                             
	                                                  #.     }                                                                          
	                                                  #.                                                                                
	my $user_data      = $$_options{user_data};       #. User-defined data that is passed on to the condition subroutine.               
	                                                  #.                                                                                
	my $search_radius  = $$_options{radius};          #. Only points within radius (in meters) will be considered.                      
	                                                  #. Default: No distance restriction                                               
	                                                  #.                                                                                
	my $sort_results   = $$_options{sort_results};    #. Sort results by distance from point.                                           
	                                                  #. Set to 0 to not sort results                                                   
	                                                  #. Default: Points are sorted by distance                                         
	
	#. Maximum number of results to return.                                                               
	#. Set to 0 to return all matching results (use with care; specifying a radius is strongly suggested) 
	#. Default: Only one point is returned                                                                
	$number_of_points_desired = 1 unless (defined $number_of_points_desired);
	
	if ( ! defined $post_condition ) {
		$post_condition = sub { my ( $result_point, $search_point, $user_data ) = @_; return ( $result_point != $_search_point ); };
	} elsif ($post_condition eq 'NONE') {
		$post_condition = undef;
	}
	
	#. Used to speed up inner loops:
	
	my $no_pre_condition  = ( defined $pre_condition )  ? 0 : 1;
	my $no_post_condition = ( defined $post_condition ) ? 0 : 1;
	
	my $no_search_radius  = ( defined $search_radius )  ? 0 : 1;
	
	#. Always sort unless explicitly told not to
	$sort_results = 1 unless ( defined $sort_results );
	
	#. Get parameters for level one past the most detailed level in the index
	
	my $max_level = $self->{max_level};
	
	my $cur_level = $max_level + 1;
	my $cur_size = 2**$cur_level;
	my $cur_max_idx = $cur_size - 1;
	
	#. Get the integer forms of the search point's latitude and longitude
	
	my $p_lat_idx = int( ( $p_lat + 90.0 )  * $cur_size / 180.0 );
	$p_lat_idx = $cur_size if ($p_lat_idx > $cur_size);  # This includes the north pole
	
	my $p_lon_idx = ( int( ( $p_lon + 180.0 ) * $cur_size / 360.0 ) % $cur_size );
	
	#. Determine the low bit of the integer latitude and longitude
	#. This is used to determine which tile edge the search point is closest to.
	
	my $lat_low_bit = $p_lat_idx & 1;
	my $lon_low_bit = $p_lon_idx & 1;
	
	#. Initialize the bit shift to one past the end of the index
	
	my $shift = -1;
	
	#. Note the search point's position in radians
	
	my $p_lat_rad;
	if (defined $$_search_point{lat_rad}) {
		$p_lat_rad = $$_search_point{lat_rad};
	} else {
		$p_lat_rad = Math::Trig::deg2rad($p_lat);
		$$_search_point{lat_rad} = $p_lat_rad;
	}
	
	my $p_lon_rad;
	if (defined $$_search_point{lon_rad}) {
		$p_lon_rad = $$_search_point{lon_rad};
	} else {
		$p_lon_rad = Math::Trig::deg2rad($p_lon);
		$$_search_point{lon_rad} = $p_lon_rad;
	}
	
	#. Determine grid sizes, etc. in meters
	
	my $NS_circumference_in_meters = $self->{polar_circumference};
	
	my $lat_meter_in_degrees = 360.0 / $NS_circumference_in_meters;
	
	my $EW_circumference_in_meters = $self->LongitudeCircumference($p_lat_rad);
	
	my $lon_meter_in_degrees = 360.0 / $EW_circumference_in_meters;
	
	my $lat_grid_in_meters = ( $NS_circumference_in_meters / 2.0 ) / $cur_size;
	
	my $lon_grid_in_meters = $EW_circumference_in_meters / $cur_size;
	
	my $p_lat_m = $NS_circumference_in_meters / 360.0 * ( $p_lat + 90.0 );
	my $p_lon_m = $EW_circumference_in_meters / 360.0 * ( $p_lon + 180.0 );
	
	#. Initialize the scratch pads and results
	
	my %distances = ();   #. Distance to each point in current set of results
	my %considered = ();  #. Points that have been considered
	                      #. (used to skip results that are already in @valid)
	my @valid = ();       #. Points that meet the search criteria
	
	#. Set the distance origin to the search point
	SetUpDistance($self->{planetary_diameter}, $p_lat_rad, $p_lon_rad);
	
	my $_results;  #. Holds the points found in the most recent result tile
	
	#. Used to exit loop early when a search radius is specified
	my $largest_distance_seen = 0;
	
	#. Loop through zoom levels from most zoomed in to least...
	while ( $cur_level >= 0 ) {
		
		my $adj_lat_idx;     #. Adjacent grid index (latitude)
		my $adj_lon_idx;
		
		my $valid_radius_m = 0;  #. Distance from search point to closest edge of grid tiles
		
		#. Set up for current grid level
		$cur_level--;                #. Zoom out one level
		$cur_size >>= 1;             #. Grid is now half the size
		my $max_grid_idx = $cur_size - 1;
		$lat_grid_in_meters *= 2.0;  #. Grid tiles now have twice the height
		$lon_grid_in_meters *= 2.0;  #. Grid tiles now have twice the width
		
		if ($cur_level < 0) {
			#. World-wide
			
			if (USE_NUMERIC_KEYS) {
				
				my $key;
				if (USE_PACKED_KEYS) {
					$key = pack("Q", ( MASK_LEVEL << 58 ) | ( MASK_LATLON << 29 ) | MASK_LATLON );
				} else {
					$key = ( MASK_LEVEL << 58 ) | ( MASK_LATLON << 29 ) | MASK_LATLON;
				}
				$_results = $$_points{$key};
				next unless defined $_results;
				
				foreach my $_point ( @$_results ) {
					next if ($considered{$_point});
					
					if ( $no_pre_condition || &$pre_condition($_point, $_search_point, $user_data) ) {
						
						my $distance;
						if (defined $distances{$_point}) {
							$distance = $distances{$_point};
						} else {
							$distance = HaversineDistance($$_point{lat_rad}, $$_point{lon_rad});
							$distances{$_point} = $distance;
							$$_point{search_result_distance} = $distance;
						}
						
						$considered{$_point} = 1;
						if ( $no_search_radius || ($distance <= $search_radius) ) {
							if ( $no_post_condition || &$post_condition($_point, $_search_point, $user_data) ) {
								push @valid, $_point;
							}
						}
					} else {  #. Pre-condition failed
						$considered{$_point} = 1;
					}
				}
			
			} else {
				#. Use split keys
				
				my $key = [ ALL, ALL, ALL ];
				$_results = $self->GetValue($key);
				next unless defined $_results;
				
				foreach my $_point ( @$_results ) {
					next if ($considered{$_point});
					
					if ( $no_pre_condition || &$pre_condition($_point, $_search_point, $user_data) ) {
						
						my $distance;
						if (defined $distances{$_point}) {
							$distance = $distances{$_point};
						} else {
							$distance = HaversineDistance($$_point{lat_rad}, $$_point{lon_rad});
							$distances{$_point} = $distance;
							$$_point{search_result_distance} = $distance;
						}
						
						$considered{$_point} = 1;
						if ( $no_search_radius || ($distance <= $search_radius) ) {
							if ( $no_post_condition || &$post_condition($_point, $_search_point, $user_data) ) {
								push @valid, $_point;
							}
						}
					} else {  #. Pre-condition failed
						$considered{$_point} = 1;
					}
				}
			
			} # END if split keys
				
		} else {
			#. Normal case
			
			#. Determine which grid tile edge the point is closest to
			#. This is done by looking at LSB of the indices of the previous (more zoomed in) level
			my $lat_low_bit = $p_lat_idx & 1;  #. Latitude previous LSB
			my $lon_low_bit = $p_lon_idx & 1;  #. Longitude previous LSB
			
			$p_lat_idx >>= 1;            #. Latitude index is now half the previous value
			$p_lon_idx >>= 1;            #. Longitude index is now half the previous value
			
			my $valid_radius_lat_m;
			my $valid_radius_lon_m;
			
			if ($lat_low_bit) {
				#. Closer to top
				
				#. Get adjacent tile's latitude grid index
				$adj_lat_idx = $p_lat_idx + 1;
				
				if ( $adj_lat_idx == $cur_size ) {
					#. We're abutting the the north pole
					$adj_lat_idx = undef;
				}
				
				#. Current search radius is the distance to bottom edge of point's grid tile
				my $lower_edge_m = $p_lat_idx * $lat_grid_in_meters;
				$valid_radius_lat_m = $p_lat_m - $lower_edge_m;
				
			} else {
				#. Closer to bottom
				
				#. Get adjacent tile's latitude grid index
				$adj_lat_idx = $p_lat_idx - 1;
				
				if ($adj_lat_idx < 0) {
					#. South polar
					$adj_lat_idx = undef;
				}
				#. Current search radius is the distance to upper edge of point's grid tile
				my $upper_edge_m = ($p_lat_idx + 1) * $lat_grid_in_meters;
				$valid_radius_lat_m = $upper_edge_m - $p_lat_m;
			}
			
			if ($lon_low_bit) {
				#. Closer to right
				$adj_lon_idx = ( $p_lon_idx + 1 ) % $cur_size;
				
				#. Current search radius is the distance to left edge of point's grid tile
				my $left_edge_m = $p_lon_idx * $lon_grid_in_meters;
				$valid_radius_lon_m = $p_lon_m - $left_edge_m;
				
			} else {
				#. Closer to left
				$adj_lon_idx = ( $p_lon_idx - 1 ) % $cur_size;
				
				#. Current search radius is the distance to right edge of point's grid tile
				my $right_edge_m = ($p_lon_idx + 1) * $lon_grid_in_meters;
				$valid_radius_lon_m = $right_edge_m - $p_lon_m;
				
			}
			
			$valid_radius_m = ( $valid_radius_lat_m < $valid_radius_lon_m ) ? $valid_radius_lat_m : $valid_radius_lon_m;
		}
		
		#. Oddly it's actually slightly faster to NOT split this code into four versions 
		#. (pre- and post-condition, pre- only, post- only and no conditions) and instead 
		#. do the checks inline as coded below.
		
		if (USE_NUMERIC_KEYS) {
			
			foreach my $lat_idx ( $p_lat_idx, $adj_lat_idx) {
				next unless defined $lat_idx;
				
				if ( $lat_idx == 0 ) {
					#. Near south pole
					my $key;
					if (USE_PACKED_KEYS) {
						$key = pack("Q", ( ($cur_level-1) << 58 ) | ( $lat_idx << 29 ) | MASK_LATLON  );
					} else {
						$key = ( ($cur_level-1) << 58 ) | ( $lat_idx << 29 ) | MASK_LATLON ;
					}
					$_results = $$_points{$key};
					next unless defined $_results;
					
					foreach my $_point ( @$_results ) {
						next if ($considered{$_point});
						
						if ( $no_pre_condition || &$pre_condition($_point, $_search_point, $user_data) ) {
						
							my $distance;
							if (defined $distances{$_point}) {
								$distance = $distances{$_point};
							} else {
								$distance = HaversineDistance($$_point{lat_rad}, $$_point{lon_rad});
								$distances{$_point} = $distance;
								$$_point{search_result_distance} = $distance;
							}
							
							if ($distance <= $valid_radius_m) {
								$considered{$_point} = 1;
								$largest_distance_seen = $distance unless ( $no_search_radius || ($distance < $largest_distance_seen) );
								if ( $no_search_radius || ($distance <= $search_radius) ) {
									if ( $no_post_condition || &$post_condition($_point, $_search_point, $user_data) ) {
										push @valid, $_point;
									}
								}
							}
							
						} else {  #. Pre-condition failed
							$considered{$_point} = 1;
						}
					}
					
				} elsif ( $lat_idx >= $max_grid_idx ) {
					#. Near north pole
					my $key;
					if (USE_PACKED_KEYS) {
						$key = pack("Q", ( ($cur_level-1) << 58 ) | ( $lat_idx << 29 ) | MASK_LATLON  );
					} else {
						$key = ( ($cur_level-1) << 58 ) | ( $lat_idx << 29 ) | MASK_LATLON ;
					}
					$_results = $$_points{$key};
					next unless defined $_results;
					
					foreach my $_point ( @$_results ) {
						next if ($considered{$_point});
						
						if ( $no_pre_condition || &$pre_condition($_point, $_search_point, $user_data) ) {
							
							my $distance;
							if (defined $distances{$_point}) {
								$distance = $distances{$_point};
							} else {
								$distance = HaversineDistance($$_point{lat_rad}, $$_point{lon_rad});
								$distances{$_point} = $distance;
								$$_point{search_result_distance} = $distance;
							}
							
							if ($distance <= $valid_radius_m) {
								$considered{$_point} = 1;
								$largest_distance_seen = $distance unless ( $no_search_radius || ($distance < $largest_distance_seen) );
								if ( $no_search_radius || ($distance <= $search_radius) ) {
									
									if ( $no_post_condition || &$post_condition($_point, $_search_point, $user_data) ) {
										push @valid, $_point;
									}
								}
							}
							
						} else {  #. Pre-condition failed
							$considered{$_point} = 1;
						}
					}
					
				} else {
					#. Normal case
					foreach my $lon_idx ( $p_lon_idx, $adj_lon_idx ) {
						my $clipped_lon_idx = $lon_idx % $cur_size;
						my $key;
						if (USE_PACKED_KEYS) {
							$key = pack("Q", ( ($cur_level-1) << 58 ) | ( $lat_idx << 29 ) | $clipped_lon_idx  );
						} else {
							$key = ( ($cur_level-1) << 58 ) | ( $lat_idx << 29 ) | $clipped_lon_idx ;
						}
						$_results = $$_points{$key};
						next unless defined $_results;
						
						foreach my $_point ( @$_results ) {
							next if ($considered{$_point});
							
							if ( $no_pre_condition || &$pre_condition($_point, $_search_point, $user_data) ) {
								
								my $distance;
								if (defined $distances{$_point}) {
									$distance = $distances{$_point};
								} else {
									$distance = HaversineDistance($$_point{lat_rad}, $$_point{lon_rad});
									$distances{$_point} = $distance;
									$$_point{search_result_distance} = $distance;
								}
								
								if ($distance <= $valid_radius_m) {
									$considered{$_point} = 1;
									$largest_distance_seen = $distance unless ( $no_search_radius || ($distance < $largest_distance_seen) );
									if ( $no_search_radius || ($distance <= $search_radius) ) {
										if ( $no_post_condition || &$post_condition($_point, $_search_point, $user_data) ) {
											push @valid, $_point;
										}
									}
								}
							} else {  #. Pre-condition failed
								$considered{$_point} = 1;
							}
						}
					}
				}
				
			}
			
		} else {
			#. Use split keys
			
			foreach my $lat_idx ( $p_lat_idx, $adj_lat_idx) {
				next unless defined $lat_idx;
				
				if ( $lat_idx == 0 ) {
					#. Near south pole
					my $key = [ $cur_level-1, $lat_idx, ALL ];
					$_results = $self->GetValue($key);
					next unless defined $_results;
					
					foreach my $_point ( @$_results ) {
						next if ($considered{$_point});
						
						if ( $no_pre_condition || &$pre_condition($_point, $_search_point, $user_data) ) {
						
							my $distance;
							if (defined $distances{$_point}) {
								$distance = $distances{$_point};
							} else {
								$distance = HaversineDistance($$_point{lat_rad}, $$_point{lon_rad});
								$distances{$_point} = $distance;
								$$_point{search_result_distance} = $distance;
							}
							
							if ($distance <= $valid_radius_m) {
								$considered{$_point} = 1;
								$largest_distance_seen = $distance unless ( $no_search_radius || ($distance < $largest_distance_seen) );
								if ( $no_search_radius || ($distance <= $search_radius) ) {
									if ( $no_post_condition || &$post_condition($_point, $_search_point, $user_data) ) {
										push @valid, $_point;
									}
								}
							}
							
						} else {  #. Pre-condition failed
							$considered{$_point} = 1;
						}
					}
					
				} elsif ( $lat_idx >= $max_grid_idx ) {
					#. Near north pole
					my $key = [ $cur_level-1, $lat_idx, ALL ];
					$_results = $self->GetValue($key);
					next unless defined $_results;
					
					foreach my $_point ( @$_results ) {
						next if ($considered{$_point});
						
						if ( $no_pre_condition || &$pre_condition($_point, $_search_point, $user_data) ) {
						
							my $distance;
							if (defined $distances{$_point}) {
								$distance = $distances{$_point};
							} else {
								$distance = HaversineDistance($$_point{lat_rad}, $$_point{lon_rad});
								$distances{$_point} = $distance;
								$$_point{search_result_distance} = $distance;
							}
							
							if ($distance <= $valid_radius_m) {
								$considered{$_point} = 1;
								$largest_distance_seen = $distance unless ( $no_search_radius || ($distance < $largest_distance_seen) );
								if ( $no_search_radius || ($distance <= $search_radius) ) {
									if ( $no_post_condition || &$post_condition($_point, $_search_point, $user_data) ) {
										push @valid, $_point;
									}
								}
							}
							
						} else {  #. Pre-condition failed
							$considered{$_point} = 1;
						}
					}
					
				} else {
					#. Normal case
					foreach my $lon_idx ( $p_lon_idx, $adj_lon_idx ) {
						my $clipped_lon_idx = $lon_idx % $cur_size;
						my $key = [ $cur_level-1, $lat_idx, $clipped_lon_idx ];
						$_results = $self->GetValue($key);
						next unless defined $_results;
						
						foreach my $_point ( @$_results ) {
							next if ($considered{$_point});
							
							if ( $no_pre_condition || &$pre_condition($_point, $_search_point, $user_data) ) {
								
								my $distance;
								if (defined $distances{$_point}) {
									$distance = $distances{$_point};
								} else {
									$distance = HaversineDistance($$_point{lat_rad}, $$_point{lon_rad});
									$distances{$_point} = $distance;
									$$_point{search_result_distance} = $distance;
								}
								
								if ($distance <= $valid_radius_m) {
									$considered{$_point} = 1;
									$largest_distance_seen = $distance unless ( $no_search_radius || ($distance < $largest_distance_seen) );
									if ( $no_search_radius || ($distance <= $search_radius) ) {
										if ( $no_post_condition || &$post_condition($_point, $_search_point, $user_data) ) {
											push @valid, $_point;
										}
									}
								}
							} else {  #. Pre-condition failed
								$considered{$_point} = 1;
							}
						}
					}
				}
				
			}
		
		} # END if split keys
		
		#. Stop searching if we have found sufficient points
		last if ( ($number_of_points_desired) && (scalar @valid >= $number_of_points_desired) );
		
		#. Stop searching if search radius exceeded
		last unless ( $no_search_radius || ( $largest_distance_seen < $search_radius) );
	} # END loop through levels
	
	#. Sort results by distance
	@valid = sort { $$a{search_result_distance} <=> $$b{search_result_distance} } @valid if ( $sort_results );
	
	#. Only include requested number of points
	if ( $number_of_points_desired ) {
		my $count_to_return = scalar @valid;
		$count_to_return = $number_of_points_desired if ($number_of_points_desired < $count_to_return);
		@valid = @valid[0 .. $count_to_return-1];
	}
	
	#. Return points found
	return ( wantarray )
	       #. Return array:
	       ? @valid
	       #. Return array reference:
	       : \@valid;
}



# ==============================================================================











=head2 Farthest( ... )

=over

C<@results = $index-E<gt>Farthest( \%point, $number_of_points_desired, \%options );>

C<$results = $index-E<gt>Farthest( \%point, $number_of_points_desired, \%options );>

Find the point or points farthest from a given point

In other words, find the points closest to a given point's antipode.

B<C<%point>>

=over

The point to search relative to

This is either a reference to a hash containing at a minimum a C<lat> and a 
C<lon> value (both in degrees) or a reference to an array giving the point.  
See the B<L<Points|/POINTS>> section above for details.

=back

B<C<$number_of_points_desired>>

=over

The number of points that should be returned.

Set to C<0> to not restrict the number of points returned or set it S<E<gt>C<0>> 
to set the maximum number of points to return.

If omitted then this will default to C<1>.

=back

B<C<%options>>

=over

The parameters for the search (all are optional):

B<C<radius>>

=over

Only return results within this distance (in meters) from search point.

If no C<radius> is specified or the C<radius> is set to C<Geo::Index::ALL> then 
all points in the index may potentially be returned.

=back

B<C<sort_results>>

=over

Sort results by distance from point

By default points returned are sorted by distance.  Set this to C<0> to not 
sort the returned points.

Although sorting is not mandatory, performing it is strongly recommended since 
otherwise the set of points returned are not guaranteed to be the farthest.

=back

B<C<pre_condition>>

=over

Reference to additional user-supplied code to determine whether each point 
should be included in the results.

This code is run before the distance from the search point to the result point 
has been calculated.

See the B<L<Condition functions|/CONDITION FUNCTIONS>> section below for syntax.

=back

B<C<post_condition>>

=over

Reference to additional user-supplied code to determine whether each point 
should be included in the results.

This code is run after the distance from the search point to the result point 
has been calculated.

By default, a C<post_condition> function that filters out the search point is 
used.  To remove this default function either specify a new one, set a value for 
C<user_data>, or set C<post_condition> to "C<NONE>".

See the B<L<Condition functions|/CONDITION FUNCTIONS>> section below for syntax.

=back

B<C<user_data>>

=over

Arbitrary user-supplied data that is passed to the condition functions.

This can be used to allow the function access to additional data structures.

If the default C<post_condition> is active and no C<user_data> value has been 
provided by the caller then this is set to the actual (non-antipodal) search 
point.

See the B<L<Condition functions|/CONDITION FUNCTIONS>> section below for syntax.

=back

=back

B<Return value>

=over

In list context the return value is a list of references to the points found or 
an empty array if none were found.

In scalar context the return value is a reference to the aforementioned list or 
C<undef> if no results were found.

For each point in the results the distance in meters from it to the search point 
will be stored in the C<search_result_distance> entry in the result point's 
hash.  In addition, the distance from a result point to the search point's 
antipode will be stored in the C<antipode_distance> entry.  These can be 
retrieved using e.g.:

  $meters_from_search_point  = $$point{search_result_distance};
  $meters_to_antipodal_point = $$point{antipode_distance};

=back

=back

=cut



#. Return farthest point or points from search point

sub Farthest($$;$$) {
	my ($self, $_search_point, $number_of_points_desired, $_options) = @_;
	
	# Allow calling as Farthest( POINT, OPTIONS ) when only a single point is desired.
	if (ref $number_of_points_desired) {
		$_options = $number_of_points_desired;
		$number_of_points_desired = 1;
	}
	
	#. Get the point index
	my $_points = $$self{index};
	
	
	if (ref $_search_point eq 'ARRAY') {
		#. Got array; expand arguments into a full point
		my $lat = $$_search_point[0];
		my $lon = $$_search_point[1];
		
		$_search_point = { 'lat'=>$lat, 'lon'=>$lon };
	}
	
	#. Get the point's position
	my $p_lat = $$_search_point{lat};
	my $p_lon = $$_search_point{lon};
	
	#. We'll be using the antipodal point as the center of the search
	my $antipode_lat = -1 * $p_lat;
	my $antipode_lon = $p_lon + 180.0;
	$antipode_lon -= 360.0 if ( $antipode_lon >= 180.0 );
	
	#. Search options; user should omit (or set to undef) inactive options:
	
	my $pre_condition  = $$_options{pre_condition};   #. Reference to subroutine returning true if current point should be considered as
	                                                  #. a possible result, false otherwise. This subroutine should not modify any data.
	                                                  #. This subroutine is called before the distance from the search point to the     
	                                                  #. result point has been calculated.                                              
	                                                  #.                                                                                
	my $post_condition = $$_options{post_condition};  #. Reference to subroutine returning true if current point should be considered as
	                                                  #. a possible result, false otherwise. This subroutine should not modify any data.
	                                                  #. This subroutine is called after the distance from the search point to the      
	                                                  #. result point has been calculated.                                              
	                                                  #.                                                                                
	                                                  #. If no post_condition and no user_data is specified then the default function   
	                                                  #. (given below, omits the search point from the results) will be used.  To over- 
	                                                  #. ride this behavior either define your own post_condition function, specify your
	                                                  #. own user_data, or set post_condition to "NONE".                                
	                                                  #.                                                                                
	                                                  #. Default post_condition:                                                        
	                                                  #.                                                                                
	                                                  #.     sub {                                                                      
	                                                  #.         my ( $result_point, $search_point, $user_data ) = @_;                  
	                                                  #.         return ( $result_point != $user_data );                                
	                                                  #.     }                                                                          
	                                                  #.                                                                                
	my $user_data      = $$_options{user_data};       #. User-defined data that is passed on to the condition subroutine.               
	                                                  #.                                                                                
	                                                  #. Default user_data: The actual (non-antipodal) search point                     
	                                                  #.                                                                                
	my $search_radius  = $$_options{radius};          #. Only points within radius (in meters) will be considered.                      
	                                                  #. Default: No distance restriction                                               
	                                                  #.                                                                                
	my $sort_results   = $$_options{sort_results};    #. Sort results by distance from point.                                           
	                                                  #. Set to 0 to not sort results                                                   
	                                                  #. Default: Points are sorted by distance                                         
	
	if ( ( ! defined $post_condition ) && ( ! defined $user_data ) ) {
		$post_condition = sub { my ( $result_point, $search_point, $user_data ) = @_; return ( $result_point != $user_data ); };
		$user_data = $_search_point;
		
	} elsif ($post_condition eq 'NONE') {
		$post_condition = undef;
	}
	
	#. Maximum number of results to return.                                                               
	#. Set to 0 to return all matching results (use with care; specifying a radius is strongly suggested) 
	#. Default: Only one point is returned                                                                
	$number_of_points_desired = 1 unless (defined $number_of_points_desired);
	
	my %options = (
	                pre_condition  => $pre_condition, 
	                post_condition => $post_condition, 
	                user_data      => $user_data, 
	                radius         => $search_radius, 
	                sort_results   => $sort_results
	              );
	
	my $_results = $self->Closest( [ $antipode_lat, $antipode_lon ], $number_of_points_desired, \%options);
	
	my $p_lat_rad;
	if (defined $$_search_point{lat_rad}) {
		$p_lat_rad = $$_search_point{lat_rad};
	} else {
		$p_lat_rad = Math::Trig::deg2rad($p_lat);
		$$_search_point{lat_rad} = $p_lat_rad;
	}
	
	my $p_lon_rad;
	if (defined $$_search_point{lon_rad}) {
		$p_lon_rad = $$_search_point{lon_rad};
	} else {
		$p_lon_rad = Math::Trig::deg2rad($p_lon);
		$$_search_point{lon_rad} = $p_lon_rad;
	}
	
	SetUpDistance($self->{planetary_diameter}, $p_lat_rad, $p_lon_rad);
	
	foreach my $_antipode (@$_results) {
		#. Distance found is actually the distance from the search point's antipodal point
		$$_antipode{antipode_distance} = $$_antipode{search_result_distance};
		
		#. Calculate and record the actual distance from the search point
		$$_antipode{search_result_distance} = HaversineDistance($$_antipode{lat_rad}, $$_antipode{lon_rad});
	}
	
	#. Return points found
	return ( wantarray )
	       #. Return array:
	       ? @$_results
	       #. Return array reference:
	       : $_results;
}



# ==============================================================================





=head2 Distance( ... )

=over

C<$meters = $index-E<gt>Distance( \%point_1, \%point_2 );>

C<$meters = $index-E<gt>Distance( \@point_1, \@point_2 );>

C<$meters = $index-E<gt>Distance( \%point_1, \@point_2 );>

C<$meters = $index-E<gt>Distance( \@point_1, \%point_2 );>

Returns the distance in meters between two points

The haversine function is used to compute the distance.  As this assumes a 
spherical body the distances returned may show errors.  Using the default 
options, these errors are up to 0.056% (north - south) or 1.12% (east - west).  
Such errors typically start becoming significant at distances over S<20 km>.

B<C<%point_1>> or B<C<@point_1>>, B<C<%point_2>> or B<C<@point_2>>

=over

The points to measure the distance between

These can be either hashes containing at a minimum a C<lat> and a C<lon> value 
(both in degrees) or arrays giving each point.  See the B<L<Points|/POINTS>> 
section above for details.

=back

=back

=cut


# Not used internally
sub Distance($$$) {
	my ($self, $p0, $p1) = @_;
	
	$self->DistanceFrom($p0);
	return $self->DistanceTo($p1);
}




=head2 DistanceFrom( ... )

=over

C<$meters = $index-E<gt>DistanceFrom( \%point_1 );>

C<$meters = $index-E<gt>DistanceFrom( \@point_1 );>

Set an initial point to measure distances from

Note that any call to C<L<Distance(...)|/Distance( ... )>> and some calls to 
C<L<Search(...)|/Search( ... )>> (those using the C<radius> or C<sort_results> 
options) will overwrite the initial point set with this method.

B<C<%point_1>> or B<C<@point_1>>

=over

The point to measure distances from

This can be either a hash containing at a minimum a C<lat> and a C<lon> value 
(both in degrees) or an array giving the point.  See the B<L<Points|/POINTS>> 
section above for details.


=back

=back

=cut



# Not used internally
sub DistanceFrom($$) {
	my ($self, $p0) = @_;
	
	if (ref $p0 eq 'ARRAY') {
		#. Got array; expand arguments into a full point
		$p0 = { 'lat'=>$$p0[0], 'lon'=>$$p0[1] };
	}
	
	$$p0{lat_rad} = Math::Trig::deg2rad($$p0{lat}) unless ($$p0{lat_rad});
	$$p0{lon_rad} = Math::Trig::deg2rad($$p0{lon}) unless ($$p0{lon_rad});
	
	SetUpDistance($self->{planetary_diameter}, $$p0{lat_rad}, $$p0{lon_rad});
}




=head2 DistanceTo( ... )

=over

C<$meters = $index-E<gt>DistanceTo( \%point_2 );>

C<$meters = $index-E<gt>DistanceTo( \@point_2 );>

Returns the distance in meters between the specified point and the one set 
earlier with C<L<DistanceFrom(...)|/DistanceFrom( ... )>>.

The haversine function is used to compute the distance.  As this assumes a 
spherical body the distances returned may show errors.  Using the default 
options, these errors are up to 0.056% (north - south) or 1.12% (east - west).  
Such errors typically start becoming significant at distances over S<20 km>.

B<C<%point_2>> or B<C<@point_2>>

=over

The point to measure distances to

This can be either a hash containing at a minimum a C<lat> and a C<lon> value 
(both in degrees) or an array giving the point.  See the B<L<Points|/POINTS>> 
section above for details.

=back

=back

=cut



# Used by Distance(...)
sub DistanceTo($$) {
	my ($self, $p1) = @_;
	
	if (ref $p1 eq 'ARRAY') {
		#. Got array; expand arguments into a full point
		$p1 = { 'lat'=>$$p1[0], 'lon'=>$$p1[1] };
	}
	
	$$p1{lat_rad} = Math::Trig::deg2rad($$p1{lat}) unless ($$p1{lat_rad});
	$$p1{lon_rad} = Math::Trig::deg2rad($$p1{lon}) unless ($$p1{lon_rad});
	
	return HaversineDistance($$p1{lat_rad}, $$p1{lon_rad});
}



#. Distance functions
#. 
#. Geo::Index uses the haversine formula to compute great circle distances 
#. between points.
#. 
#. Three versions are supported: a fallback version written in Perl (used if the 
#. C versions fail to compile) and two accelerated versions written in C, one 
#. using floats and the other using doubles.  By default the C float version is 
#. used; if it fails to compile then the Perl version is used.  Use of a specific 
#. version can also be requested with Geo::Index->SetDistanceFunctionType(...).
#. 
#. The Perl version uses doubles.  When using floats instead of doubles the loss 
#. of precision is typically under a meter (about 2 meters in the worst case).
#. #. Compared to the errors inherent to the haversine function, this loss of 
#. precision is negligable.

#. Here are the results of benchmarking the three versions on a fairly high-end 
#. workstation (higher numbers are better).  The test dataset is 1 million random
#. points and each search type was performed once for each point in random order.
#. The same points were used for each test and they were in the same order.  All
#. searches returned results as lists except for the 'all points' search which 
#. returned a list reference.  The default options (Earth, 20-level index) were 
#. used for each test.  Each version's benchmark was run 32 times; some jitter 
#. was observed.
#. 
#. Average number of operations per second using each version (rounded):
#. Percentages (in parentheses) are relative to the pure-Perl version.
#. 
#. Results for 32 iterations of each test:
#. 
#. Operation                            Perl     C double (%)    C float (%) 
#. --------------------------------    ------    ------------    ------------
#. Add point to index                   35861     36067 (101)     36060 (101)
#. Search: return all points           256127    256877 (101)    252116  (98)
#. Search: sort, max 5                   6733      8718 (129)      8860 (132)
#. Search: sort, radius 1000, max 5     45364     49063 (108)     49831 (110)
#. Search: sort, radius 1000            45902     49418 (108)     51673 (113)
#. Search: max 5                       198499    190404  (96)    204905 (103)
#. Search: radius 1000, max 5           46942     51295 (109)     54554 (116)
#. Search: radius 1000                  47908     51941 (108)     55522 (116)


#. These will be set to references to the Perl versions of the functions
my $SetUpDistance_perl      = undef;
my $HaversineDistance_perl  = undef;
my $ComputeAreaExtrema_perl = undef;
my $fast_log2_perl          = undef;

#. Choose whether to use Perl or C code for distance and log2 calculations
#. Default is to use the Perl functions

# Used by new(...)
sub SetDistanceFunctionType($) {
	my ($type) = @_;
	
	#. Get function pointers for the Perl versions (if not already recorded)
	$SetUpDistance_perl      = *SetUpDistance      unless (defined $SetUpDistance_perl);
	$HaversineDistance_perl  = *HaversineDistance  unless (defined $HaversineDistance_perl);
	$ComputeAreaExtrema_perl = *ComputeAreaExtrema unless (defined $ComputeAreaExtrema_perl);
	$fast_log2_perl          = *fast_log2          unless (defined $fast_log2_perl);
	
	#. Choose the type of functions to use:
	
	if ( $type eq 'perl' ) {
		#. Switch to using Perl code for distance and log2 calculations
		
		*Geo::Index::SetUpDistance      = $SetUpDistance_perl;
		*Geo::Index::HaversineDistance  = $HaversineDistance_perl;
		*Geo::Index::fast_log2          = $fast_log2_perl;
		*Geo::Index::ComputeAreaExtrema = $ComputeAreaExtrema_perl;
		$ACTIVE_CODE = 'perl';
		
		$C_CODE_ACTIVE = 0;
		
		return 1; # success
		
	} elsif ( $C_CODE_COMPILED && $type eq 'double' ) {
		#. Switch to using C double code for distance and log2 calculations
		
		*Geo::Index::SetUpDistance      = *Geo::Index::SetUpDistance_double;
		*Geo::Index::HaversineDistance  = *Geo::Index::HaversineDistance_double;
		*Geo::Index::fast_log2          = *Geo::Index::fast_log2_double;
		*Geo::Index::ComputeAreaExtrema = *Geo::Index::ComputeAreaExtrema_double;
		$ACTIVE_CODE = 'double';
		
		$C_CODE_ACTIVE = 1;
		
		return 1; # success
	
	} elsif ( $C_CODE_COMPILED && $type eq 'float' ) {
		#. Switch to using C float code for distance and log2 calculations
		
		*Geo::Index::SetUpDistance      = *Geo::Index::SetUpDistance_float;
		*Geo::Index::HaversineDistance  = *Geo::Index::HaversineDistance_float;
		*Geo::Index::ComputeAreaExtrema = *Geo::Index::ComputeAreaExtrema_float;
		*Geo::Index::fast_log2          = *Geo::Index::fast_log2_float;
		
		$ACTIVE_CODE = 'float';
		
		$C_CODE_ACTIVE = 1;
		
		return 1; # success
	}
	
	return undef; # Failed, no change
}


#. Returns the type of low-level functions that is active
#. (one of 'perl', 'float', or 'double')
# used by GetConfiguration, t/low-level.t
sub GetLowLevelCodeType() {
	return $ACTIVE_CODE;
}

#. Returns reference to list of the supported low-level function types
#. (list values as per GetLowLevelCodeType)
# used by GetConfiguration, t/low-level.t
sub GetSupportedLowLevelCodeTypes() {
	return [ @SUPPORTED_CODE ];
}

#. Perl version of the distance functions

# Used by Search(...)
#. For the values that the module is interested in the 
#. return value is the same as ceil(log2(n))           
sub fast_log2($) {
	my ($n) = @_;
	my $i = 0;
	my $c = 1;
	for ( $n = ceil( $n ); 
	      $n > $c; 
	      $c<<=1, $i++ ) { }
	return $i;
}

#. Perl doesn't have a log2(n) function; if one wants  
#. to use it the following performs it:                

# Not used internally
sub log2($) {
	my ($n) = @_;
	return log($n) / log(2);
}

#. Used internally by the Perl versions of SetUpDistance and HaversineDistance
my ( $DistanceFrom_diameter, $DistanceFrom_lat_1, $DistanceFrom_lon_1 );
my $DistanceFrom_cos_lat_1;

#. Specify the point to get distances from
#. Diameter is in meters, Lat and Lon are in radians
#.                                                                               
#. If possible, this function will be replaced by an equivalent written in C.    
sub SetUpDistance($$$) {
	my ($new_diameter, $new_lat_1, $new_lon_1) = @_;
	$DistanceFrom_diameter = $new_diameter;
	$DistanceFrom_lat_1 = $new_lat_1;
	$DistanceFrom_lon_1 = $new_lon_1;
	$DistanceFrom_cos_lat_1 = cos( $DistanceFrom_lat_1 );
}

#. Returns the approximate distance from previously-set point to specified point 
#. Lat and Lon are in radians, return value is in meters                         
#.                                                                               
#. If possible, this function will be replaced by an equivalent written in C.    
sub HaversineDistance($$) {
	my ($lat_0, $lon_0)= @_;
  
	my $sin_lat_diff_over_2 = sin( ( $lat_0 - $DistanceFrom_lat_1 ) / 2.0 );
	my $sin_lon_diff_over_2 = sin( ( $lon_0 - $DistanceFrom_lon_1 ) / 2.0 );
	
	my $n = ( $sin_lat_diff_over_2 * $sin_lat_diff_over_2 ) 
	        + (
	            ( $sin_lon_diff_over_2 * $sin_lon_diff_over_2 )
	            * $DistanceFrom_cos_lat_1
	            * cos( $lat_0 )
	          );
	
	#. The haversine formula may get messy around antipodal points so clip to the largest sane value.
	if ( $n < 0.0 ) { $n = 0.0; }
	
	return $DistanceFrom_diameter  * asin( sqrt($n) );
}




=head2 GetConfiguration( )

=over

C<%configuration = $index-E<gt>GetConfiguration( );>

Returns the running configuration of the Geo::Index object.

See also C<L<GetStatistics(...)|/GetStatistics( )>> and C<examples/show_configuration.pl>

The return value is a hash with the following entries:

=over

B<C<key_type>> - The key type in use:

=over

'C<text>' for text keys (e.g. 'C<12:345,6789>')

'C<numeric>' for 64-bit numeric keys

'C<packed>' for 64-bit numeric keys packed into an 8-byte string

=back

B<C<supported_key_types>> - The types of keys that can be used

=over

Value is a reference to a list of supported key types (as given above).

=back

B<C<code_type>> - The type of low-level code in use:

=over

'C<perl>' for Perl functions

'C<float>' for C functions mostly using C<float> values.

'C<double>' for C functions mostly using C<double> values.

=back

B<C<supported_code_types>> - The types of low-level code that can be used

=over

Value is a reference to a list of supported code types (as given above).

=back

B<C<levels>> - Number of levels in index (excluding the global level)
	
B<C<planetary_radius>> - Average planetary radius (in meters)

B<C<polar_circumference>> - Polar circumference (in meters)

B<C<equatorial_circumference>> - Equatorial circumference (in meters)
	
B<C<size>> - Number of points currently indexed

B<C<tile_meters>> - Size in meters (at the equator) of each tile the at 
most-detailed level of index

=back

=back

=cut


#. Returns the index's current configuration
# not used internally
sub GetConfiguration($) {
	my ($self) = @_;
	my %config = ();
	
	#. Low-level configuration
	$config{key_type}  = ( USE_NUMERIC_KEYS ) ? ( USE_PACKED_KEYS ) ? 'packed' : 'numeric' : 'text';
	$config{supported_key_types} = [ 'text', 'numeric', 'packed' ];
	$config{code_type} = $self->GetLowLevelCodeType();
	$config{supported_code_types} = $self->GetSupportedLowLevelCodeTypes();
	
	$config{module_version} = "$VERSION";
	$config{module_version} =~ s/^v//;
	
	if ($C_CODE_COMPILED == 1) {
		#. C low-level function library is loaded
		
		my $c_code_version = Geo::Index::GetCCodeVersion();
		my $mask = ( 1 << 10 ) - 1;
		my $major_version = ( $c_code_version >> 20 ) & $mask;
		my $minor_version = ( $c_code_version >> 10 ) & $mask;
		my $sub_version   =   $c_code_version         & $mask;
		$config{c_code_version} = "${major_version}.${minor_version}.${sub_version}";
		
	} else {
		#. No C low-level function library
		$config{c_code_version} = undef;
	}
	
	#. Index depth
	$config{levels}    = $self->{levels};
	
	#. Planery size
	$config{planetary_radius}         = $self->{planetary_radius};
	$config{polar_circumference}      = $self->{polar_circumference};
	$config{equatorial_circumference} = $self->{equatorial_circumference};
	
	#. Number of points in index
	$config{size} = scalar keys %{$self->{indices}};
	
	#. Width in meters of each tile at most-detailed level of index
	$config{tile_meters} = $config{equatorial_circumference} / ( 2**$config{levels} );
	
	return %config;
}




=head2 GetStatistics( )

=over

C<@stats = $index-E<gt>GetStatistics( );>

Returns statistics regarding the Geo::Index object.

See also C<L<GetConfiguration(...)|/GetConfiguration( )>> and C<examples/show_configuration.pl>

The return value is a list with one entry per level.  Each list entry is a hash 
reference giving statistics for a single level of the index and contains the 
following entries:

=over

B<C<level>> - The level number the statistics are for

B<C<points>> - Total number of points indexed in this level

B<C<tiles>> - Number of tiles containing at least one point

B<C<min_tile_points>> - Minimum number of points in a non-empty tile

B<C<max_tile_points>> - Maximum number of points in a non-empty tile

B<C<avg_tile_points>> - Average number of points in a non-empty tile

=back

=back

=cut



#. Returns statistics regarding the current index
# not used internally
sub GetStatistics($) {
	my ($self) = @_;
	
	my $_index = $self->{index};
	my $levels = $self->{levels};
	
	my @stats = ();
	
	foreach my $key (keys %$_index) {
		my ($level, $lat, $lon);
		
		if ( USE_NUMERIC_KEYS ) {
			if ( USE_PACKED_KEYS ) {
				#. packed numeric key
				$key = unpack("Q", $key);
			}
			#. numeric key
			
			$level = $key >> 58;
			$lat   = ($key >> 29 ) & MASK_LATLON;
			$lon   = $key & MASK_LATLON;
			
			$lat = 'ALL' if ($lat == MASK_LATLON);
			$lon = 'ALL' if ($lon == MASK_LATLON);
			
			next if ($level > $levels);
		} else {
			#. text key
			($level,$lat,$lon) = split /[:,]/, $key;
			
			next if ($level eq 'ALL');
		}
		
		$stats[$level]->{level} = $level;
		
		my $count = scalar @{$$_index{$key}};
		
		$stats[$level]->{points} += $count;
		$stats[$level]->{tiles}++;
		$stats[$level]->{avg_tile_points} += $count;
		
		if (
		     ( ! defined $stats[$level]->{min_tile_points} ) ||
		     ( $count < $stats[$level]->{min_tile_points} )
		   ) {
			$stats[$level]->{min_tile_points} = $count;
		}
		if (
		     ( ! defined $stats[$level]->{max_tile_points} ) ||
		     ( $count > $stats[$level]->{max_tile_points} )
		   ) {
			$stats[$level]->{max_tile_points} = $count;
		}
		
	}
	
	for (my $level=0; $level<$levels; $level++) {
		my $tiles = $stats[$level]->{tiles};
		if ( $tiles ) {
			$stats[$level]->{avg_tile_points} /= $tiles;
		} else {
			$stats[$level]->{avg_tile_points} = undef;
		}
	}
	
	return @stats;
}




=head2 Sweep( ... )

=over

C<$index-E<gt>Sweep( );>

C<$index-E<gt>Sweep( \%point );>

C<$index-E<gt>Sweep( \@points );>

C<$index-E<gt>Sweep( undef, \@extra_keys );>

C<$index-E<gt>Sweep( \%point, \@extra_keys );>

C<$index-E<gt>Sweep( \@points, \@extra_keys );>

Remove data generated by searches from some or all points

The fields that will be removed are C<search_result_distance> and C<antipode_distance>.

Called on its own (with no point or points specified) this method will remove 
data generated by searches from all points.

A list of additional keys to remove can optionally be supplied.  To request 
vacuuming of all points with additional keys specified, use C<undef> instead  
of C<\%point> or C<\@points>.

See also C<L<Vacuum(...)|/Vacuum( ... )>>.

B<C<%point>> or B<C<@points>>

=over

The point or a list of points to remove metadata from.

=back

B<C<@extra_keys>>

=over

List of additional keys to remove

=back

=back

=cut


#. Remove data generated search methods from some or all points
# not used internally
sub Sweep($;$$) {
	my ($self, $_points, $_extra_keys) = @_;
	
	if ( ! defined $_points ) {
		# Use all points in index if none were specified
		my $key;
		if (USE_NUMERIC_KEYS) {
			if (USE_PACKED_KEYS) {
				$key = pack("Q", ( MASK_LEVEL << 58 ) | ( MASK_LATLON << 29 ) | MASK_LATLON );
			} else {
				$key = ( MASK_LEVEL << 58 ) | ( MASK_LATLON << 29 ) | MASK_LATLON;
			}
		} else {
			$key = [ ALL, ALL, ALL ];
		}
		$_points = $self->GetValue($key);
		
	} elsif ( ref $_points eq 'HASH' ) {
		# Build list if passed a single point
		$_points = [ $_points ];
	}
	
	if ( ref $_extra_keys eq 'ARRAY' ) {
		foreach my $_point ( @$_points ) {
			delete $$_point{search_result_distance};
			delete $$_point{antipode_distance};
			foreach my $key (@$_extra_keys) {
				delete $$_point{$key};
			}
		}
	} else {
		foreach my $_point ( @$_points ) {
			delete $$_point{search_result_distance};
			delete $$_point{antipode_distance};
		}
	}
}




=head2 Vacuum( ... )

=over

C<$index-E<gt>Vacuum( );>

C<$index-E<gt>Vacuum( \%point );>

C<$index-E<gt>Vacuum( \@points );>

C<$index-E<gt>Vacuum( undef, \@extra_keys );>

C<$index-E<gt>Vacuum( \%point, \@extra_keys );>

C<$index-E<gt>Vacuum( \@points, \@extra_keys );>

Remove all data generated by Geo::Index from some or all points

The fields that will be removed are: C<lat_rad>, C<lon_rad>, C<circumference>, 
C<search_result_distance>, C<antipode_distance>.

Called on its own (with no point or points specified) this method will remove 
all generated data from all points.

A list of additional keys to remove can optionally be supplied.  To request 
vacuuming of all points with additional keys specified, use C<undef> instead  
of C<\%point> or C<\@points>.

See also C<L<Sweep(...)|/Sweep( ... )>>.

B<C<%point>> or B<C<@points>>

=over

The point or a list of points to remove metadata from.

=back

B<C<@extra_keys>>

=over

List of additional keys to remove

=back

=back

=cut


#. Remove all data generated by Geo::Index from some or all points
# not used internally
sub Vacuum($;$$) {
	my ($self, $_points, $_extra_keys) = @_;
	
	if ( ! defined $_points ) {
		# Use all points in index if none were specified
		my $key;
		if (USE_NUMERIC_KEYS) {
			if (USE_PACKED_KEYS) {
				$key = pack("Q", ( MASK_LEVEL << 58 ) | ( MASK_LATLON << 29 ) | MASK_LATLON );
			} else {
				$key = ( MASK_LEVEL << 58 ) | ( MASK_LATLON << 29 ) | MASK_LATLON;
			}
		} else {
			$key = [ ALL, ALL, ALL ];
		}
		$_points = $self->GetValue($key);
		
	} elsif ( ref $_points eq 'HASH' ) {
		# Build list if passed a single point
		$_points = [ $_points ];
	}
	
	if ( ref $_extra_keys eq 'ARRAY' ) {
		foreach my $_point ( @$_points ) {
			delete $$_point{lat_rad};
			delete $$_point{lon_rad};
			delete $$_point{circumference};
			delete $$_point{search_result_distance};
			delete $$_point{antipode_distance};
			foreach my $key (@$_extra_keys) {
				delete $$_point{$key};
			}
		}
	} else {
		foreach my $_point ( @$_points ) {
			delete $$_point{lat_rad};
			delete $$_point{lon_rad};
			delete $$_point{circumference};
			delete $$_point{search_result_distance};
			delete $$_point{antipode_distance};
		}
	}
}




=head2 PointCount( )

=over

C<$count = $index-E<gt>PointCount( );>

Returns the number of points currently in index

=back

=cut


#. Returns the number of points currently in index
# Used by t/trampoline.t
sub PointCount($) {
	my ($self) = @_;
	return scalar keys %{$self->{indices}}
}




=head2 AllPoints( )

=over

C<@all_points = $index-E<gt>AllPoints( );>

C<$all_points = $index-E<gt>AllPoints( );>

Returns all points currently in index

B<Return value>

=over

In list context the return value is a list of references to all points in the 
index or an empty array if there are no points in the index.

In scalar context the return value is a reference to the aforementioned list or 
a reference to an empty list if there are no points in the index.

=back

=back

=cut


#. Returns a list of all points currently in index
sub AllPoints($) {
	my ($self) = @_;

	my $_results = $self->Search( [0,0], { radius => ALL, quick_results => 1 } );
	
	if (wantarray) {
		return @{$$_results[0]};
	} else {
		return $$_results[0];
	}
	
	# Slower method:
	
	# my @return = ();
	# foreach my $_set ( @$_results ) {
	# 	push @return, @$_set if ( defined $_set );
	# }
	# 
	# if (wantarray) {
	# 	return @return;
	# } else {
	# 	return \@return;
	# }
}




# ==============================================================================

#. These methods are experimental and may be removed in future


#. END Experimental methods

# ==============================================================================

#. The code below is only used internally by Geo::Index


#: Proximity and indexing helper functions

#. Note that for performance reasons the code from these functions may have been 
#. inlined into the various methods and C functions.                             


#: Convert latitude/longitude pair from degrees to integers suitable for indexing
#. 
#> IN:  lat, lon         -> The point's latitude and longitude in degrees
#> 
#> OUT: lat_int, lon_int -> The point's latitude and longitude as scaled integers
#. 
#. Input ranges are:
#.    latitude:  [ -90 degrees .. 90 degrees ]
#.    longitude: [ -180 degrees .. 180 degrees )
#. 
#. Output ranges are:
#.    latitude:  [ 0 .. max_size ]      =  [ 0 .. 2**levels ]
#.    longitude: [ 0 .. max_size - 1 ]  =  [ 0 .. 2**levels - 1 ]
#.
#. Note that the latitude range includes both poles.  The longitude range only 
#. includes the antimeridian once and thus its output integer range is one 
#. smaller.  Code that converts the returned integers to index keys must take 
#. this into account.

# Used by Index and Search
sub GetIntLatLon($$) {
	my ($self, $lat, $lon) = @_;
	
	my $lat_int = int( ( $lat + 90.0 )  * $self->{max_size} / 180.0 );
	$lat_int = $self->{max_size} if ($lat_int > $self->{max_size});
	
	my $lon_int = int( ( $lon + 180.0 ) * $self->{max_size} / 360.0 ) % $self->{max_size};
	
	return ($lat_int, $lon_int);
}


#: Convert latitude from degrees to integers suitable for indexing
#. 
#> IN:  lat     -> The point's latitude in degrees
#> 
#> OUT: lat_int -> The point's latitude as scaled integers
#. 
#. Input ranges are:
#.    latitude:  [ -90 degrees .. 90 degrees ]
#. 
#. Output ranges are:
#.    latitude:  [ 0 .. max_size ]  =  [ 0 .. 2**levels ]
#.
#. Note that the latitude range includes both poles.  Code that converts the 
#. returned integer to part of an index keys must take this into account.

# Not used
sub GetIntLat($$) {
	my ($self, $lat) = @_;
	
	my $lat_int = int( ( $lat + 90.0 )  * $self->{max_size} / 180.0 );
	$lat_int = $self->{max_size} if ($lat_int > $self->{max_size});
	
	return ($lat_int);
}


#: Convert longitude from degrees to integers suitable for indexing
#. 
#> IN:  lon     -> The point's longitude in degrees
#> 
#> OUT: lon_int -> The point's longitude as scaled integers
#. 
#. Input ranges are:
#.    longitude: [ -180 degrees .. 180 degrees )
#. 
#. Output ranges are:
#.    longitude: [ 0 .. max_size - 1 ]  =  [ 0 .. 2**levels - 1 ]

# Not used
sub GetIntLon($$) {
	my ($self, $lon) = @_;
	return int( ( $lon + 180.0 ) * $self->{max_size} / 360.0 ) % $self->{max_size};
}


#: Return length of circle of latitude (in meters) at given latitude (in radians)
#. 
#. Circles of latitude run east-west (e.g. the equator is a circle of latitude).
#. Values are approximate.  The diameters are those for an oblate spheroid but 
#. the math assumes a sphere.

# Use by Closest, OneMeterInDegrees
sub LongitudeCircumference($$) {
	my ($self, $radians) = @_;
	return abs(cos( $radians )) * $self->{equatorial_circumference};
}


=head2 OneMeterInDegrees( ... )

=over

C<$index-E<gt>OneMeterInDegrees( $latitude );>

Returns length in degrees of one meter (N/S and E/W) at given latitude

Values are approximate.  The diameters are those for an oblate spheroid but 
the math assumes a sphere.  As one approaches the poles these values get 
heavily distorted; code that uses them needs to take this into account.

See also C<L<OneDegreeInMeters(...)|/OneDegreeInMeters( ... )>>.

B<C<$latitude>>

=over

The latitude in radians

=back

B<Return value>

=over

An two-element list containing the width and height in meters of one degree 
at the given latitude:

C<( I<degrees_of_latitude>, I<degrees_of_longitude> )>

=back

=back

=cut


#: Returns length in degrees of one meter (N/S and E/W) at given latitude
#. 
#> IN:  latitude -> The latitude in radians
#> 
#> OUT: An array containing the width and height in meters of one degree at the 
#>      given latitude: ( DEGREES_OF_LATITUDE, DEGREES_OF_LONGITUDE )
#. 
#. Values are approximate.  The diameters are those for an oblate spheroid but 
#. the math assumes a sphere.  As one approaches the poles these values get 
#. heavily distorted; code that uses them needs to take this into account.

# Not used
sub OneMeterInDegrees($$) {
	my ($self, $latitude) = @_;
	
	my $NS_circumference_in_meters = $self->{polar_circumference};
	my $EW_circumference_in_meters = LongitudeCircumference( $self, $latitude );
	
	if ( $EW_circumference_in_meters ) {
		return ( ( 360.0 / $NS_circumference_in_meters ), ( 360.0 / $EW_circumference_in_meters ) )
	} else {
		return ( ( 360.0 / $NS_circumference_in_meters ), undef )
	}
}


=head2 OneDegreeInMeters( ... )

=over

C<$index-E<gt>OneMeterInDegrees( $latitude );>

Returns length in meters of one degree (N/S and E/W) at given latitude

Values are approximate.  The diameters are those for an oblate spheroid but 
the math assumes a sphere.  As one approaches the poles these values get 
heavily distorted; code that uses them needs to take this into account.

See also C<L<OneMeterInDegrees(...)|/OneMeterInDegrees( ... )>>.

B<C<$latitude>>

=over

The latitude in radians

=back

B<Return value>

=over

An two-element list containing the width and height in degrees of one meter 
at the given latitude:

C<( I<north_south_meters>, I<east_west_meters> )>

=back

=back

=cut


#: Returns length in meters of one degree (N/S and E/W) at given latitude
#. 
#> IN:  latitude -> The latitude in radians
#> 
#> OUT: An array containing the width and height in degrees of one meter at the 
#>      given latitude: ( NORTH_SOUTH_METERS, EAST_WEST_METERS )
#. 
#. Values are approximate.  The diameters are those for an oblate spheroid but 
#. the math assumes a sphere.  As one approaches the poles these values get 
#. heavily distorted; code that uses them needs to take this into account.

# Not used
sub OneDegreeInMeters($$) {
	my ($self, $latitude) = @_;
	
	my $NS_circumference_in_meters = $self->{polar_circumference};
	my $EW_circumference_in_meters = LongitudeCircumference( $self, $latitude );
	
	return ( ( $NS_circumference_in_meters / 360.0 ), ( $EW_circumference_in_meters / 360.0 ) )
}


#: Returns the latitude and longitude indices for a point at a given level
#. This method is used by Index(...)
#. 
#> IN:  level   -> The level number to get indices for
#>      lat_int -> Point's integer latitude (as returned by GetIntLatLon(...)
#>      lon_int -> Point's integer longitude (as returned by GetIntLatLon(...)
#> 
#> OUT: lat_idx -> Point's integer latitude within the requested level
#>      lon_idx -> Point's integer longitude within the requested level

# Used by Index
sub GetIndices($$$) {
	my ($self, $level, $lat_int, $lon_int) = @_;
	
	my $shift = $self->{max_level} - $level;
	
	my $lat_idx = $lat_int >> $shift;
	my $lon_idx = $lon_int >> $shift;
	
	return ($lat_idx, $lon_idx);
}




# *** Method aliases ***

sub index;                 *index                = *Index;
sub index_points;          *index_points         = *IndexPoints;
sub unindex;               *unindex              = *Unindex;

sub build_points;          *build_points         = *BuildPoints;
sub add_value;             *add_value            = *AddValue;
sub get_value;             *get_value            = *GetValue;

sub search;                *search               = *Search;
sub search_by_bounds;      *search_by_bounds     = *SearchByBounds;
sub closest;               *closest              = *Closest;
sub farthest;              *farthest             = *Farthest;
sub all_points;            *all_points           = *AllPoints;

sub distance;              *distance             = *Distance;
sub distance_from;         *distance_from        = *DistanceFrom;
sub distance_to;           *distance_to          = *DistanceTo;

sub one_meter_in_degrees;  *one_meter_in_degrees = *OneMeterInDegrees;
sub one_degree_in_meters;  *one_degree_in_meters = *OneDegreeInMeters;

sub get_configuration;     *get_configuration    = *GetConfiguration;
sub get_statistics;        *get_statistics       = *GetStatistics;

sub sweep;                 *sweep                = *Sweep;
sub vacuum;                *vacuum               = *Vacuum;
sub point_count;           *point_count          = *PointCount;

# Internal methods:

sub set_distance_function_type;          *set_distance_function_type         = *SetDistanceFunctionType;
sub get_low_level_code_type;             *get_low_level_code_type            = *GetLowLevelCodeType;
sub get_supported_low_level_code_types;  *get_supported_low_level_code_types = *GetSupportedLowLevelCodeTypes;
sub set_up_distance;                     *set_up_distance                    = *SetUpDistance;
sub haversine_distance;                  *haversine_distance                 = *HaversineDistance;
sub get_int_lat_lon;                     *get_int_lat_lon                    = *GetIntLatLon;
sub get_int_lat;                         *get_int_lat                        = *GetIntLat;
sub get_int_lon;                         *get_int_lon                        = *GetIntLon;
sub longitude_circumference;             *longitude_circumference            = *LongitudeCircumference;
sub get_indices;                         *get_indices                        = *GetIndices;

=head2 Alternate method names

Geo::Index uses CamelCase for its method names.

For those who prefer using snake case, alternate method names are provided:

    Method               Alternate name
    -----------------    --------------------
    Index                index
    IndexPoints          index_points
    Unindex              unindex
    
    BuildPoints          build_points
    AddValue             add_value
    GetValue             get_value
    
    Search               search
    SearchByBounds       search_by_bounds
    Closest              closest
    Farthest             farthest
    AllPoints            all_points
    
    Distance             distance
    DistanceFrom         distance_from
    DistanceTo           distance_to
    
    OneMeterInDegrees    one_meter_in_degrees
    OneDegreeInMeters    one_degree_in_meters
    
    GetConfiguration     get_configuration
    GetStatistics        get_statistics
    
    Sweep                sweep
    Vacuum               vacuum
    PointCount           point_count


=head1 CONDITION FUNCTIONS

The C<L<Search(...)|/Search( ... )>>, C<L<SearchByBounds(...)|/SearchByBounds( ... )>>, 
C<L<Closest(...)|/Closest( ... )>>, and C<L<Farthest(...)|/Farthest( ... )>> 
methods allow a user-supplied condition function to filter potential results.

If present, these condition functions are called for each potential search 
result.  They should be idempotent* and could potentially be called multiple 
times for a given point.  The code should return B<TRUE> (e.g. C<1>) if a potential 
point should be included in the results or B<FALSE> (e.g. C<0> or C<undef>) if the 
point should be excluded.

For C<L<Search(...)|/Search( ... )>>, C<L<Closest(...)|/Closest( ... )>>, and 
C<L<Farthest(...)|/Farthest( ... )>>, the C<pre_condition> function runs before 
the distance to the result point has been calculated and the C<post_condition> 
function runs after it has been calculated. For C<L<SearchByBounds(...)|/SearchByBounds( ... )>> 
no distances are calculated and the function is simply called once per point.

* Functions can set outside values provided they do not affect any values 
used internally by C<L<Search(...)|/Search( ... )>> and so long as those 
outside values have no effect on the condition's outcome.  Such behavior is, 
of course, frowned upon.

The parameters to the condition function are, in order:

=over

B<C<$_result_point>>

=over

Reference to the potential search result being checked

=back

B<C<$_search_point>>

=over

Reference to the point at the center of the search

For C<SearchByBounds(...)> this is instead the bounding box:
S<C<[ I<west>, I<south>, I<east>, I<north> ]>>

=back

B<C<$user_data>>

=over

Arbitrary user-supplied data

=back

=back

For example, the options set in the following code allows all points in the 
results except for the one named 'S<Point Nada>':

    $options{pre_condition} = 
        sub {
              my ( $_result_point, $_search_point, $user_data ) = @_;
              if ( $$_result_point{name} eq $user_data ) {
                return 0;  # Exclude result
              }
              return 1;    # Point is a valid search result
            };
    $options{user_data} = "Point Nada";

To exclude the search point from the search results use:

    $options{post_condition} = 
        sub {
              my ( $_result_point, $_search_point, $user_data ) = @_;
              return ( $_result_point != $_search_point );
            };

or more concisely

    $options{post_condition} = sub { return $_[0] != $_[1]; };

In general, C<post_condition> functions should be preferred since the overhead 
of the Perl function call is typically larger than that of the distance 
calculation.  By checking the distance first, running the C<post_condition> 
function might not be necessary.




=head1 PERFORMANCE

=head2 Overview

Geo::Index is intended for stand-alone applications that need a way to quickly 
perform proximity searches on relatively small datasets (at most a few million 
points).  Typical search speeds are three to five orders of magnitude faster 
than a linear search.  For larger datasets and for applications running in a 
server environment using something like PostGIS is more appropriate.

Indexing speed is about 50,000 points per second when C<levels> is 20.  Search 
speeds are highly dependent on the data indexed and on search parameters but are 
typically in the neighborhood of a few thousand searches per second.

Memory usage tends to be rather high; for 1,000,000 points the index is S<~3.2 GB> 
for tightly clustered points or S<~4.6 GB> when spread evenly world-wide.  The 
size of an index grows linearly with each added point at a rate of about S<4 kB> 
per point.  When a point is first encountered whilst searching its size will 
increase by about 100 bytes (this only happens once per point).

Since performance is so dependant on data and usage, the the user is encouraged 
to test all available options while developing their application before choosing 
the one that works fastest.  The C<examples/benchmark.pl> script included with 
this module may be helpful for measuring this module's performance.

=head2 General tips

Here are some guidelines for best results:

=over

=item * B<Requesting results as a list reference is faster than asking for a plain list.>

That is, e.g., S<C<$results = Search(...);>> is faster than C<@results = Search(...);>

=item * B<Post-conditions are faster than pre-conditions.>

Benchmarking has shown that the cost of the Perl function call is higher than 
that of the distance-related code.  Thus there is probably no reason to use 
pre-conditions.  Put concisely,

=over

 $results = $index->Search( $point, { post_condition => $code_ref } );

=back

is faster than

=over

 $results = $index->Search( $point, { pre_condition => $code_ref } );

=back

=item * B<Choose an appropriate value for C<levels> when creating the index>

The C<L<Search(...)|/Search( ... )>> method has best performance when the size of the most 
detailed level of the index has a smaller physical size than the radius of a 
typical search.  For example, if your searches are typically for points within 
100 meters then an index with C<levels> should be set to at least 18 (~75 meters 
at the equator) to yield best results; if typical searches have 10 meter radius 
then C<levels> should be 22.

The C<L<Closest(...)|/Closest( ... )>> method works best when the most detailed level of the 
index contains a single point per tile and search points lie close to potential 
result points.

To help tune the C<levels> value, the C<L<GetConfiguration( )|/GetConfiguration( )>> method can 
be used to find out the physical size of the most detailed level along with 
statistics on the number of points per index tile.

=item * B<Use the C<quick_results> option when possible.>

Filtering points and combining them into a single, flat list can be very 
expensive.  Many applications can tolerate getting additional points beyond 
those matching the search criteria.  An example of this is drawing points on 
a map; if points are clipped to the visible area when they are 
drawn it may not matter if some of them lie outside of it.

=item * B<Use C<L<Search(...)|/Search( ... )>> instead of C<L<Closest(...)|/Closest( ... )>> when you have a search radius.>

The C<L<Closest(...)|/Closest( ... )>> function is most efficient when no search radius is 
specified or when result points lie very close to the search point.  Closeness 
is relative to the tile size of the most detailed index level; for the default 
index depth (C<20>), "very close" is roughly within about 100 meters.

When clipping results to a maximal radius it is typically much faster to use 
C<L<Search(...)|/Search( ... )>> with the C<sort_results> and C<max_results> options*.

For example, to find the closest C<$n> points within distance C<$d> of a point 
C<$p> it is usually much faster to use

=over

 %options = (
              max_results    => $n, 
              radius         => $d, 
              sort_results   => 1,
              post_condition => sub { return $_[0] != $_[1]; }
            );
 $results = $index->Search( $p, \%options );

=back

instead of 

=over

 $results = $index->Closest( $p, $n { radius => $d } );

=back

* The C<post_condition> shown in the example omits the search point from 
the results and is needed to fully emulate the behavior of C<Closest(...)>.

=back

=head2 Technical discussion

Both C<L<Search(...)|/Search( ... )>> and C<L<SearchByBounds(...)|/SearchByBounds( ... )>> are very fast since 
they can find the relevant index tiles in linear time.  Since the time needed to 
filter the results is directly proportional to the number of points retrieved 
from the index, best performance occurs when the size of the most detailed tiles 
is smaller than that of the typical search radius or search bounds.

Searches run using C<L<Closest(...)|/Closest( ... )>> are done starting from the most 
detailed level and work upwards.  Best performance occurs when a result is found 
in the first few iterations.  If the first iteration that finds points yields a 
large number of points then performance will suffer since the distance to each 
of these points will need to be measured to find the closest.  For similar 
reasons, requesting a large number of closest points in a single call will also 
impact performance.  The C<L<Farthest(...)|/Farthest( ... )>> method is largely a wrapper for 
C<L<Closest(...)|/Closest( ... )>> and thus exhibits similar behavior.

Some functions within Geo::Index have optional implementations written in C.  If 
these are active (by default they are whenever possible) searches typically run 
25% to 50% faster.

Whenever possible Geo::Index uses numeric index keys.  Compared to text index 
keys, numeric keys improve performance with about 30% faster speed and about 50% 
smaller index memory usage.  The downside to numeric keys is that they are less 
legible to humans while debugging.  (Whether numeric or text keys are used can 
be changed by setting the appropriate value at the top of C<Geo/Index.pm>)

=head2 Benchmark results

Typical benchmark results run on a modern workstation using numeric keys and 
double-precision C low-level code with the index containing 1,000,000 points 
are as follows:

=over

=item

B<C<L<IndexPoints(...)|/IndexPoints( ... )>>>

Points can be added to an index at the rate of about 50,000 per second.

=item

B<C<L<Search(...)|/Search( ... )>>>

Typical searches returning values run at about 25,000 to 50,000 searches per 
second.  Worst-case performance is under 50 searches per second and searches 
returning no results run at over 100,000 searches per second.  The overhead of 
traversing the results is fairly negligable.

Quick searches run at 120,000 to 150,000 searches per second.  Actually doing 
anything with the results slows things down a lot.  Including traversal of the 
results, a typical quick search runs at 40,000 to 100,000 searches per second 
with the worst-case being about 80 searches per second.

If distances to the result points are not needed, quick searches are typically 
about 75% faster than normal ones albeit with about 5 times as many results 
being returned.

=item

B<C<L<SearchByBounds(...)|/SearchByBounds( ... )>>>

For the C<L<SearchByBounds(...)|/SearchByBounds( ... )>> method run time correlates with the 
size of the bounding box with smaller bounding boxes typically yielding faster 
run times.

A fairly typical search yielding about 50 results runs at about 10,000 searches 
per second in normal mode and about 30,000 searches per second in quick mode.
A nearly worst case example is a search returning 100,000 points; this will run 
at about 5 searches per second in normal mode or about 8,000 searches per second 
in quick mode.


=item

B<C<L<Closest(...)|/Closest( ... )>>>

For the Closest(...) method the highest performance is seen when there are 
result points close to the search point.  Search speeds for the single closest 
point are typically in excess of 20,000 per second for close-by results or 
about 8,000 per second when results are far away.  Worst case speeds of about 
1,000 searches per second occur when all indexed points are in the hemisphere 
opposite the search point.

=item

B<C<L<Farthest(...)|/Farthest( ... )>>>

For the Farthest(...) method the highest performance is seen when there are 
result points nearly antipodal to the search point.  Search speeds for the 
single farthest point are typically in excess of 20,000 per second when 
nearly-antipodal points exist.  Worst case speeds of about 1,000 searches per 
second occur when all indexed points are in the same hemisphere as the search 
point.

=back

Note that the numbers above are approximate and are highly dependant on the 
data being searched, the type of search being run, and on the number of results 
returned.  Actual searches may be an order of magnitude or more slower.  

A sample benchmark run can be found in C<examples/benchmark.txt>  To run the 
benchmarks yourself you can run C<examples/benchmark.pl>  It needs the 
Devel::Size and Time::HiRes modules installed and a single run takes about 8 
minutes.

Since Perl constants cannot be changed from the commandline you will need to 
edit the C<Geo/Index.pm> to force the use of numeric keys, packed numeric keys, 
or text keys.  This can be done by uncommenting the appropriate lines at the 
head of the file (look for C<USE_NUMERIC_KEYS> and C<USE_PACKED_KEYS>).  When 
running C<benchmark.pl>, the various other options can be found at the top of 
the script.  When writing your own programs you can switch between the Perl and 
C single- or double-precision low-level code by using the C<function_type> 
option when calling C<new(...)>.

=head2 Potential optimizations

The high cost of constructing and traversing the results seems inherent to the 
Perl language and there does not seem to be any way to avoid it.  The is some 
potential for optimization though:

=over

=item *

The C<pre_condition> and C<post_condition> function calls might be sped up by 
assigning them to function handles (much as is done with C<HaversineDistance>, 
etc.) instead of making the calls by dereferencing the variables.

=item *

Performance could potentially be improved by splitting the current combined 
index into individual indices for each level.  Having smaller keys and indices 
should result in higher performance but the additional layer of indirection 
could slow things down in some circumstances.

=item *

Improvements might be possible to the performance of C<Closest( I<n>, ...)> 
where S<C<I<n>>E<gt>1> and per-point distances are not needed by the caller.  At 
each iteration of the algorithm the previously-used search radius gives the 
maximal distance to all points already found, obviating the need to calculate 
every point's distance.  Only points in the final level of the search would need 
to have their distances calculated.  The downside to this method is that the 
point distances would not be available for all points in a result set (only for 
those found in the final search level).

=item *

A number of alternative datastructures were explored for the point index but 
benchmarking showed plain Perl hashes to be by far the most efficient.  It is 
possible, though in my opinion unlikely, that a faster data structure choice 
exists that is suitable for use in this module.

=back

=head1 THEORY OF OPERATION

=head2 Overview

A given index comprises sets of tiles at various zoom levels with each tile 
containing a list of the points that lie within it.  The lowest level of the 
index covers the entire globe.  Each higher index level contains twice as many 
tiles in each direction.  At each zoom level points are linearly mapped to 
grid tiles based on their latitudes and longitudes using an equirectangular 
projection.  This is fairly analogous to how typical web slippy maps are 
organized (though they use a pseudo-mercator projection).

As one approaches the poles the tiles become increasingly distorted with the 
area (in square meters) covered by each tile becoming progressively smaller.
The distance in meters for one degree of longitude gets smaller as one moves 
away from the equator.  The distance in meters for one degree of latitude, 
however, remains constant at all latitudes.

Each tile has a name that gives its zoom level and position.  These names are 
used as keys into a Perl hash allowing the quick retrieval of the points that 
lie within a given tile.  The various search methods are designed to efficiently 
pull points from this index and filter them in various ways.  The format used 
for the keys is described in the B<Tile naming> section below.

Additional datastructures (e.g. the list of all points in the index) are also 
present but knowing their details is not needed to understand how the index 
functions.  In the descriptions below, some minor (but often critical) details 
have been omitted and some simplifications have been made; these details (mainly 
edge cases) are discussed in the code comments.


=head2 Populating the index

When a point is added to the index it is stored multiple times in the index 
hash, once for each level.  This is done as follows:

=over

=item *

The point's latitude and longitude are converted to integers.  This is done 
using a simple linear mapping.  In pseudo-code, the equations used are:

 max_size = 2**levels
 
 integer_latitude  = floor( ( latitude + 90.0 )  * max_size / 180.0 )
 integer_latitude  = max_size - 1 if (integer_latitude == max_size)
 
 integer_longitude = floor( ( longitude + 180.0 ) * max_size / 360.0 ) % max_size
	
The values for C<latitude> and C<longitude> are in degrees and C<levels> is 
the number of levels in the index (not counting the S<global one).>

=item *

Each index level is looped through from the index's maximum level to C<0>.  At 
each level, the key (comprised of C<level>, C<integer_latitide>, and 
C<integer_longitide>, see also below) is used to retrieve the corresponding 
value from the index hash.  This value is a reference to the list of points that 
lie within the grid tile named by the key.  The point being indexed is added to 
the retrieved list.  If there is no list stored in the index for the current key 
then a new list is created and added.  As a special case, all points adjacent to 
the poles (that is points with integer latitudes of C<0> or C<max_size - 1>) use 
the longitude C<ALL> in their keys.

Once the point has been added, the integer latitudes and longitudes as well as 
the C<max_size> are shifted right by one bit in preparation for the the next 
level.

=item *

Once a the point has been added to the index at each level, the point is added to 
the global index entry using the key S<C<ALL>, C<ALL>, C<ALL>>.  (All indexed 
points can be found under this key.)

=back

=head2 Basic searching

The C<L<Search(...)|/Search( ... )>> method is typically used to find all points lying 
within a given radius of a search point.  Two steps are performed by this 
method: retrieval of preliminary results and filtering of the results based on 
the search criteria.

If no search radius was specified, if a global search was requested, or if the 
search radius covers more than half the globe then the preliminary results are 
all points in the index.  Otherwise, the preliminary results are gathered as 
follows:

The appropriate tile zoom level to use is determined using:

 shift = ceil( log2( search_radius / half_circumference ) )
 level = max_level - shift

This results in the smallest level that could potentially contain all result 
points within a single tile.  

The search radius (in meters) is converted to two search angular radii, one for 
latitude and one for longitude.  This is done since the number of meters per 
degree longitude decreases as one approaches the poles.  Thus the north-south 
(latitude) search radius remains constant at all latitudes but the east-west 
(longitude) search radius increases as one nears the poles.

Each extreme is converted to an integer and shifted right by the determined 
C<shift>,  The preliminary results are retrieved from the index by iterating 
over the keys for the computed level, bounded by the integer extrema.  This 
typically, but not always, results in a list of pointers to four tiles' points.

If the C<quick_results> option is active then this preliminary list of lists of 
points is returned.  If not then the points are filtered to only include those 
matching the search criteria.  The filtered points are optionally sorted and 
then returned.  Note that when large numbers of points have been found this 
filtering can be very slow; see B<L<Performance|/PERFORMANCE>> above for details.

=head2 Proximity searching

The C<L<Closest(...)|/Closest( ... )>> and C<L<Farthest(...)|/Farthest( ... )>> methods find the points 
closest to (or farthest from) a search point.  The C<L<Closest(...)|/Closest( ... )>> method 
works as follows:

The search starts at the most detailed level of the index and proceeds to the 
least detailed (C<0>).  At each level, the grid tile that the search point lies 
in along with the three closest grid squares are identified.  The method used 
for selecting the adjacent tiles is to look at the least-significant bits of the 
integer position at the previous (more detailed) level.  A C<1> bit for the 
latitude selects tiles to the north, a C<0> bit the ones to the south.  Likewise 
a C<1> for the longitude selects the ones east and a C<0> the ones west.

Now that the four tiles have been identified, the largest radius from the search 
point to the tile edges is determined.  The distance from the search point to 
each point within the four tiles is measured.  If the point is within the radius 
computed and it passes any pre- or post-condition tests it is added to the 
results list.  To speed up processing, points that have already been rejected 
along with the distances so far measured are cached.  As a convenience, by  
default a filter is applied that omits the search point from the results.

Once all points within a level's four chosen tiles have been gathered a check is 
done to see whether at least the requested number of points have been found.  If 
they have then the loop ends, if not then the next (less-detailed) level is 
processed.

By default, the results are then sorted by distance which ensures that the 
closest results are earliest in the list.  This is necessary since although the 
nature of the algorithm tends to place closer points earlier in the results 
there is no inherent order to the points added from a particular index level.
Lastly, the requested number of result points is returned.

The C<L<Farthest(...)|/Farthest( ... )>> method is largely implemented as a wrapper for 
C<L<Closest(...)|/Closest( ... )>>.  It functions by finding the closest points to the search 
point's antipode.

=head2 Searching by bounding box

The C<L<SearchByBounds(...)|/SearchByBounds( ... )>> method works much the same as C<L<Search(...)|/Search( ... )>>
method.  Instead of computing extrema of a search circle, those of the supplied 
bounding box are used.  The tile level used is C<max( I<latitude_level>, I<longitude_level> )> 
where I<C<latitude_level>> and I<C<longitude_level>> are the most detailed levels that 
could potentially (given their extrema's angular distances) contain their 
respective extrema within a single tile in each direction.  The remainder of the 
method is identical to that of C<L<Search(...)|/Search( ... )>> albeit with all 
distance-related code removed.

=head2 Tile naming (key generation)

As mentioned earlier, keys consist of a zoom level, a latitude, and a longitude.
Each key uniquely names a given tile.

Zoom levels are either integers between C<0> and the maximum zoom level or the 
special zoom level C<ALL> (with the value C<-1>) that covers the entire globe.
Latitudes and longitudes are integers between C<0> and one less than the maximum 
grid size for the level.  The tiles immediately adjacent to the poles are 
treated differently.  In these areas the coverage of each tile is quite small 
and the algorithm around the poles would normally be complex.  To accommodate 
these issues, the special value C<ALL> (with the value C<-1>) is used for the 
longitude of the polar tiles (those areas with the lowest or highest latitude 
value for the key's level).  All points lying in a polar region are assigned to 
that region's overarching C<ALL> tile.  At the global level all three components 
are set to C<ALL>.

If Perl has been compiled with 64-bit support then each key is packed into a 
64 bit integer.  The level is stored in the upper 6 bits (bits 58 .. 63), the 
integer latitude in the next 29 bits (bits 29 .. 57), and the integer longitude 
in the low 29 bits (bits 0 .. 28).  To represent the C<ALL> value all bits in 
the relevant field are set to C<1>.  Note that even on 32-bit systems Perl is 
often compiled with 64-bit support.

If Perl does not have 64-bit support then a different format is used.  In most 
places within Geo::Index, keys are stored as three-element array references.
The first field contains the level, the second the integer latitude and the 
third the integer longitude.  If present, C<ALL> values are stored as-is as 
their integer value (C<-1>).  For accessing the index, keys are converted to 
strings with the format "I<level>C<:>I<latitude>C<,>I<longitude>" with the 
literal string "C<ALL>" being used for C<ALL> values.

=head2 Object structure

Each index object is a hash containing a number of entries  These are:

=over

B<C<$self-E<gt>{index}>> - The points index

Entry is a hash reference.  Keys are tile names (as discussed above), values are lists of 
point references.

B<C<$self-E<gt>{indices}>> - Indices used for each point

Entry is a hash reference.  Keys are point references, values are lists of tile names.

B<C<$self-E<gt>{positions}>> - Each point's position when indexed

Entry is a hash reference.  Keys are point references, values are two-element lists giving 
each point's latitude and longitude at the time it was indexed.

B<C<$self-E<gt>{levels}>> - Number of levels in the index (excluding the 
global level)

B<C<$self-E<gt>{max_level}>> - The highest-resolution level number (i.e. C<levels> - 1)

B<C<$self-E<gt>{max_size}>> - Number of grid tiles in each direction at most detailed level of index

B<C<$self-E<gt>{planetary_radius}>> - The planetary radius used by the index 
(in meters)

B<C<$self-E<gt>{polar_circumference}>> - The polar circumference used by the 
index (in meters)

B<C<$self-E<gt>{equatorial_circumference}>> - The equatorial circumference 
used by the index (in meters)

=back



=head1 BUGS AND DEFICIENCIES

=head3 Known issues

=over

=item * This module is not believed to be thread-safe.  In specific:

=over

=item * 
The C<SetUpDistance(...)> function stores the first point's position in 
global variables.

To fix this, C<DistanceFrom*(...)> and C<DistanceTo*(...)> would 
need to be removed plus C<SetUpDistance*(...)> and 
C<HaversineDistance*(...)> would need to be combined into a single 
4-argument C<HaversineDistance*(...)> function.  Calling code would need 
to be modified as appropriate.  In terms of performance, the overall cost of 
doing this is likely quite low.

=item * 
The search code stores distances computed for a specific search into the point 
datastructures.  If multiple concurrent searches are run against a single index 
then distances computed by one search may overwrite those from another search.  
This can lead to inconsistent results.

To fix this a per-search distance hash would need to be maintained.  This could 
have serious performance implications and would preclude returning the point 
distances within the point hashes.  The distances could, however, be returned in 
an additional datastructure.

=item *
Adding and deleting points to/from the index is not atomic.  Running e.g. a 
search while points are being added or deleted can lead to unpredictable 
behavior (up to and including the program crashing).

One could fix this by adding object-level locks:

=over

=item * Block concurrent calls to the C<Index(...)> and C<Unindex(...)>methods

=item * Block calls to the C<Index(...)> and C<Unindex(...)> methods while searches are running

=item * Block calls to C<Search(...)> I<et al.> when the C<Index(...)> or C<Unindex(...)> methods are active 

=back

=back

=back

=over

=item *
Including the same point in multiple indices or searches at the same time could 
lead to interesting results.

As mentioned above, this is due to the storage of search result distances within 
the points and not within the index object.  Each search that involves a given 
point will likely overwrite its C<search_result_distance> value.

This could be encountered in a number of ways.  For example, a search using a 
condition function that itself runs a search against the second index could be 
problematic.  This could be encountered even when using a single index.  For 
example, if code relies on the distances values from a search it should save a 
copy of them before running subsearches against the same set of points.  If this 
is not done then the distance values from the first search may be overwritten by 
those of the subsequent searches.

=item *

Geo::Index uses the spherical haversine formula to compute distances.  While 
quite fast, its accuracy over long distances is poor, with a worst case error 
of about 0.1% (22 km).  Since the module already has provision for changing the 
backends used for the distance methods, adding a new backend to, for example, 
compute accurate distances on e.g. a WGS-84 spheroid would be simple and 
straight-forward.

=item *

In places the code can be repetitious or awkward in style.  This was done 
because, especially in the inner loops, speed has been favoured over clarity.

=back

=head3 Reporting bugs

Please submit any bugs or feature requests either to C<bug-geo-index at rt.cpan.org>, 
through L<CPAN's web interface|http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Index>,
or through L<Github|https://github.com/Alex-Kent/Geo-Index/issues>.  In any case I will 
receive notification when you do and you will be automatically notified of progress 
on your submission as it takes place. Any other comments can be sent to C<akh@cpan.org>.

=head1 VERSION HISTORY

B<0.0.8> (2019-04-10) - Corrected internal links, CPAN release

=over

=item * Corrected POD links to use spaces instead of underscores

=item * Uploaded to CPAN

=back



B<0.0.7> (2019-04-08) - Methods can now be called using snake case

=over

=item * Added method aliases so that CamelCase methods can also be called using snake_case.

=back



B<0.0.6> (2019-04-05) - Bug fixes, additional tests

=over

=item * B<C<GetIntLatLon(...)>>: Fixed off-by-one error at the north pole

This affected B<C<L<Index(...)|/Index( ... )>>> and B<C<L<Search(...)|/Search( ... )>>>.

=item * B<C<GetIntLat(...)>>: Fixed off-by-one error at the north pole

=item * More thorough tests

=item * Improved documentation

=back



B<0.0.5> (2019-04-04) - Added methods, enhancements

=over

=item * B<C<L<PointCount( )|/PointCount( )>>>: New method

=item * B<C<L<AllPoints( )|/AllPoints( )>>>: New method

=item * B<C<L<Sweep(...)|/Sweep( ... )>>>: Added C<extra_keys> option

=item * B<C<L<Vacuum(...)|/Vacuum( ... )>>>: Added C<extra_keys> option

=back



B<0.0.4> (2019-04-03) - Switched from Inline::C to XS for low-level C functions, minor restructuring

=over

=item * Low-level C code is now in C<Index.xs>.

All references to Inline::C have been removed.

=item * Deprecated B<C<DeletePointIndex(...)>> and replaced it with B<C<L<Unindex(...)|/Unindex( ... )>>>

=back



B<0.0.3> (2019-04-01) - Added Vacuum(...), Sweep(...), and tests plus bug fixes and minor enhancements

=over

=item * B<C<L<Sweep(...)|/Sweep( ... )>>>: New method

=item * B<C<L<Vacuum(...)|/Vacuum( ... )>>>: New method

=item * Added tests

=item * B<C<L<SearchByBounds(...)|/SearchByBounds( ... )>>>: Bug fixes

=item * B<C<L<new(...)|/Geo::Index-E<gt>new(_..._)>>>: Added C<quiet> option

=back


B<0.0.2> (2019-03-31) - Bug fixes and minor enhancements

=over

=item * B<C<L<Index(...)|/Index( ... )>>>: Fixed bug for points added near (but not at) the north pole

=item * B<C<L<GetConfiguration( )|/GetConfiguration( )>>>: Added C<supported_key_types>, C<supported_code_types>, and C<tile_meters> values>

=back



B<0.0.1> (2018-03-30) - Initial release

=head1 AUTHOR

Alex Kent Hajnal S<  > C<akh@cpan.org> S<  > L<https://alephnull.net/software>


=head1 COPYRIGHT

Geo::Index

Copyright 2019 Alexander Hajnal, All rights reserved

This module is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.  See L<perlartistic>.


=cut


1;
