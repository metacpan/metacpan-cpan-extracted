#!/usr/bin/perl

# This program benchmarks various searches, etc.
# It typically takes about 8 minutes to run.

# Sample results from can be found in sample_benchmark.txt


# Repeatedly run tests over at least this many seconds
# ----------------------------------------------------
my $MIN_TEST_SECONDS = 5;


# Type of low-level function to use
# ---------------------------------
#my $FUNCTION_TYPE = 'perl';    # Uncomment to request use of Perl low-level functions
#my $FUNCTION_TYPE = 'float';   # Uncomment to request use of C low-level functions using single-precision floating point
my $FUNCTION_TYPE = 'double';  # Uncomment to request use of C low-level functions using double-precision floating point


# Force key type
# --------------
#
# These must be set from within outside of Geo/Index.pm
# The appropriate lines are near the top of the file
#
# To use text keys:
#   USE_NUMERIC_KEYS should be 0
#
# To use numeric keys:
#   USE_NUMERIC_KEYS should be 1
#   USE_PACKED_KEYS should be 0
#
# To use packed numeric keys:
#   USE_NUMERIC_KEYS should be 1
#   USE_PACKED_KEYS should be 1


# Number of points to create
# --------------------------
my $POINT_COUNT = 1_000_000;


# Point area
# ----------
# Point area is specified as the size (in degrees) of a box centered on the 
# equator to evenly distribute points into.  Set to 0 to cover the entire 
# Earth.  Densities shown assume 1,000,000 points.

my $POINT_AREA = 0;
# Points evenly distributed across the Earth

#my $POINT_AREA = 0.000898315277071;
# Points evenly distributed over a 100m x 100 m area
# This gives a density of about 100,000,000 per square km (1 per 10 cm x 10 cm)

#my $POINT_AREA = 0.00898315277071;
# Points evenly distributed over a 1 km x 1 km area
# Density is 1 per square meter or 1,000,000 per square km
# Spacing between points is about 1 m

#my $POINT_AREA = 0.0898315277071;
# Points evenly distributed over a 10 km x 10 km area
# Density is 10,000 per square km
# Spacing between points is about 10 m

#my $POINT_AREA = 0.898315277071;
# Points evenly distributed over a 100 km x 100 km area
# Density is 100 per square km
# Spacing between points is about 100 m

#my $POINT_AREA = 8.98315277071;
# Points evenly distributed over a 1,000 km x 1,000 km area
# Density is 1 per square km
# Spacing between points is about 1 km


# Number of levels in index
# -------------------------
my $LEVELS = 20;  # This is the default
#my $LEVELS = 21;


# Points to index
# ---------------
# If you want to run this program against your own set of points then populate 
# this array.  Each point added should be a reference to a two-element list 
# giving the decimal latitude (-90.0 .. 90.0) and longitude (-180.0 .. 180) of 
# the point.

# The points being indexed (populated below)
my @points = ();

# Example of custom set of points:
#my @points = ( [-20, 30], [90, 0], [-180, -39] );



# To manually tweak search tile sizes
# -----------------------------------
# See the documentation for Search(...) and SearchByBounds(...) for details
my $tile_adjust = 0;


# Fixed radius to use for calls that need it
# ------------------------------------------
my $radius = 10_000;  # value is in meters



# END User-configurable options










print "\nThis benchmark will likely take about 8 minutes to run\n\n";

$FUNCTION_TYPE = 'float' unless ($FUNCTION_TYPE);

use warnings;
use strict;

use Geo::Index;
use Devel::Size qw(size total_size);
use Time::HiRes;

sub ShowConfiguration($);
sub commify($);
sub PrettyPrint($);
sub benchmark_code($$);

my @benchmarks = ();
my $benchmark;




# .--------------------------------------.
# | Generate evenly-spread random points |
# '--------------------------------------'

# Reset the random number generator so that we get the same points every time
srand 0;

if ( scalar @points ) {
	print "Using user-supplied points\n";
	
} else {
	# Only generate points if the user didn't supply any
	
	print "Generating points\n";
	
	my $OFFSET = $POINT_AREA / 2.0;
	
	# Create points
	for (my $i=0; $i<$POINT_COUNT; $i++) {
		# Points are distributed evenly over the globe, not evenly over all latitudes
		# The call to rand() intentionally overshoots so that we can (potentially) 
		# get both poles.
		
		my ($lat, $lon);
		
		if ($POINT_AREA == 0) {
			# Points distributed evenly across the Earth
			for ( $lat = rand(2.000_000_1); 
			             $lat>2.0; 
			             $lat = rand(2.000_000_1) ) { };
			$lat = Math::Trig::rad2deg(Math::Trig::acos($lat - 1.0)) - 90.0;
			
			# Longitude is evenly distributed over all lines of latitude
			$lon = rand(360.0) - 180.0;
			
		} else { 
			# Points distributed evenly across a square area
			$lat = rand($POINT_AREA) - $OFFSET;
			$lon = rand($POINT_AREA) - $OFFSET;
		}
		
		# Create the point
		push @points, { lat=>$lat, lon=>$lon };
	}
	
	print "\n";
	
}



# .--------------.
# | Index points |
# '--------------'

print "Indexing points\n";
my $index;

$benchmark = benchmark_code( $MIN_TEST_SECONDS, sub {
              $index = Geo::Index->new( undef, { levels => $LEVELS, function_type=>$FUNCTION_TYPE } );
              $index->IndexPoints(\@points);
            });
push @benchmarks, [ "Create index, ".scalar(@points)." points", $$benchmark[1], scalar(@points)*$$benchmark[0], undef ];

my $initial_points_memory = Devel::Size::total_size(\@points);
my $initial_index_memory  = Devel::Size::total_size($index);

print "Levels: $LEVELS\tPoints: ".PrettyPrint($initial_points_memory)."\tIndex: ".PrettyPrint($initial_index_memory),"\n";




# .----------------------------.
# | Show current configuration |
# '----------------------------'

print "\n";

ShowConfiguration($index);

print "\n";




# .------------------------.
# | Generate search points |
# '------------------------'

print "Generating search points\n";

use List::Util qw(shuffle);
my @search = shuffle @points;

print "\n";



# .-----------------------.
# | Run search benchmarks |
# '-----------------------'

print "Searching\n\n";



{
	# Dummy search to prime the index
	
	# By doing this, the slight overhead of computing the radian versions of each 
	# point's position won't skew the benchmark results.  Once computed, the radian 
	# values won't get recomputed.
	
	my $search_point = $search[0];
	my $results = $index->Search(
	                              $search_point, 
	                              {
	                                tile_adjust=>0, 
	                                max_results=>1, 
	                                sort_results=>1, 
	                              }
	                            );
}



my $no_search_point_in_results = 	sub {  return $_[0] != $_[1];  };



if (1) { # Search, normal results
	push @benchmarks, undef; # blank line
	foreach my $radius ( 100, 330, 1_000, 3_300, 10_000, 33_000, 100_000, 330_000, 1_000_000 ) {
		print "\nSearch( point , { radius=>$radius, no_search_point_in_results } )\n";
		my $i=0;
		my $total = 0;
		my $max = scalar @search;
		$benchmark = benchmark_code( $MIN_TEST_SECONDS, sub { 
		                                    my $search_point = $search[($i++ % $max)]; 
		                                    my $results = $index->Search(
		                                                                  $search_point, 
		                                                                  {
		                                                                    tile_adjust=>$tile_adjust, 
		                                                                    radius=>$radius, 
		                                                                    post_condition => $no_search_point_in_results
		                                                                  }
		                                                                );
		                                    $total += (defined $results) ? scalar(@$results) : 0;
		                                   } );
		print "Average of " . ($total / $i) . " results per search\n";
		
		push @benchmarks, [ "Search, normal, r=".($radius/1000)." km", $$benchmark[1], $$benchmark[0], ($total / $i) ];
		
		$i=0;
		$total = 0;
		$max = scalar @search;
		$benchmark = benchmark_code( $MIN_TEST_SECONDS, sub { 
		                                    my $search_point = $search[($i++ % $max)]; 
		                                    my $results = $index->Search(
		                                                                  $search_point, 
		                                                                  {
		                                                                    tile_adjust=>$tile_adjust, 
		                                                                    radius=>$radius, 
		                                                                    post_condition => $no_search_point_in_results
		                                                                  }
		                                                                );
		                                    if (defined $results) {
		                                      foreach my $point ( @$results ) {
		                                        my $temp = $$point{lat};
		                                        $total++;
		                                      }
		                                    }
		                                   } );
		print "Average of " . ($total / $i) . " results per search\n";
		
		push @benchmarks, [ "+traveral (read value)", $$benchmark[1], $$benchmark[0], ($total / $i) ];
		
	}
}



if (1) { # Search, quick results
	push @benchmarks, undef; # blank line
	foreach my $radius ( 100, 330, 1_000, 3_300, 10_000, 33_000, 100_000, 330_000, 1_000_000 ) {
		print "\nSearch( point , { radius=>$radius, quick_results } )\n";
		my $i=0;
		my $total = 0;
		my $max = scalar @search;
		$benchmark = benchmark_code( $MIN_TEST_SECONDS, sub {
		                                    my $search_point = $search[($i++ % $max)];
		                                    my $results = $index->Search(
		                                                                  $search_point,
		                                                                  {
		                                                                    tile_adjust=>$tile_adjust,
		                                                                    shift=>0,
		                                                                    radius=>$radius,
		                                                                    quick_results=>1
		                                                                  } );
		                                    #my $this_total = 0;
		                                    if (defined $results) {
		                                      foreach my $subarray ( @$results ) {
		                                        if (defined $subarray) {
		                                          #$this_total += scalar(@$subarray);
		                                          $total += scalar(@$subarray);
		                                        }
		                                      }
		                                    }
		                                    #print "\t$this_total results\n";
		                                    #$total += $this_total;
		                                  } );
		
		push @benchmarks, [ "Search, quick, r=".($radius/1000)." km", $$benchmark[1], $$benchmark[0], ($total / $i) ];
		
		$i=0;
		$total = 0;
		$max = scalar @search;
		$benchmark = benchmark_code( $MIN_TEST_SECONDS, sub {
		                                    my $search_point = $search[($i++ % $max)];
		                                    my $results = $index->Search(
		                                                                  $search_point,
		                                                                  {
		                                                                    tile_adjust=>$tile_adjust,
		                                                                    shift=>0,
		                                                                    radius=>$radius,
		                                                                    quick_results=>1
		                                                                  } );
		                                    #my $this_total = 0;
		                                    if (defined $results) {
		                                      #$index->DistanceFrom($search_point);
		                                      foreach my $subarray ( @$results ) {
		                                        if (defined $subarray) {
		                                          #$this_total += scalar(@$subarray);
		                                          #$total += scalar(@$subarray);
		                                          foreach my $point ( @$subarray ) {
		                                            #my $distance = $index->DistanceTo($point);
		                                            my $temp = $$point{lat};
		                                            $total++;
		                                          }
		                                        }
		                                      }
		                                    }
		                                    #print "\t$this_total results\n";
		                                    #$total += $this_total;
		                                  } );
		
		print "Average of " . ($total / $i) . " results per search\n";
		push @benchmarks, [ "+traversal (read value)", $$benchmark[1], $$benchmark[0], ($total / $i) ];
		
		$i=0;
		$total = 0;
		$max = scalar @search;
		$benchmark = benchmark_code( $MIN_TEST_SECONDS, sub {
		                                    my $search_point = $search[($i++ % $max)];
		                                    my $results = $index->Search(
		                                                                  $search_point,
		                                                                  {
		                                                                    tile_adjust=>$tile_adjust,
		                                                                    shift=>0,
		                                                                    radius=>$radius,
		                                                                    quick_results=>1
		                                                                  } );
		                                    #my $this_total = 0;
		                                    if (defined $results) {
		                                      $index->DistanceFrom($search_point);
		                                      foreach my $subarray ( @$results ) {
		                                        if (defined $subarray) {
		                                          #$this_total += scalar(@$subarray);
		                                          #$total += scalar(@$subarray);
		                                          foreach my $point ( @$subarray ) {
		                                            my $distance = $index->DistanceTo($point);
		                                            #my $temp = $$point{lat};
		                                            $total++;
		                                          }
		                                        }
		                                      }
		                                    }
		                                    #print "\t$this_total results\n";
		                                    #$total += $this_total;
		                                  } );
		
		push @benchmarks, [ "+traversal (compute distance)", $$benchmark[1], $$benchmark[0], ($total / $i) ];
		
	}
}



if (1) { # Closest
	push @benchmarks, undef; # blank line
	foreach my $count ( 1, 3, 10, 33, 100, 330, 1_000 ) {
		print "\nClosest( point, $count )\n";
		my $i=0;
		my $total = 0;
		my $max = scalar @search;
		$benchmark = benchmark_code( $MIN_TEST_SECONDS, sub {
		                                    my $search_point = $search[($i++ % $max)];
		                                    my $results = $index->Closest( $search_point, $count );
		                                    $total += (defined $results) ? scalar(@$results) : 0;
		                                  } );
		print "Average of " . ($total / $i) . " results per search\n";
		
		push @benchmarks, [ "Closest, $count", $$benchmark[1], $$benchmark[0], ($total / $i) ];
	}
}



if (1) { # Farthest
	push @benchmarks, undef; # blank line
	foreach my $count ( 1, 3, 10, 33, 100, 330, 1_000 ) {
		print "\nFarthest( point, $count )\n";
		my $i=0;
		my $total = 0;
		my $max = scalar @search;
		$benchmark = benchmark_code( $MIN_TEST_SECONDS, sub {
		                                    my $search_point = $search[($i++ % $max)];
		                                    my $results = $index->Farthest( $search_point, $count );
		                                    $total += (defined $results) ? scalar(@$results) : 0;
		                                  } );
		print "Average of " . ($total / $i) . " results per search\n";
		
		push @benchmarks, [ "Farthest, $count", $$benchmark[1], $$benchmark[0], ($total / $i) ];
	}
}



if (1) { # Closest, with radius
	push @benchmarks, undef; # blank line
	foreach my $count ( 1, 3, 10, 33, 100, 330, 1_000 ) {
		print "\nClosest( point, $count, { radius=>100_000 } )\n";
		my $i=0;
		my $total = 0;
		my $max = scalar @search;
		$benchmark = benchmark_code( $MIN_TEST_SECONDS, sub {
		                                    my $search_point = $search[($i++ % $max)];
		                                    my $results = $index->Closest( $search_point, $count, { radius=>100_000 } );
		                                    $total += (defined $results) ? scalar(@$results) : 0;
		                                  } );
		print "Average of " . ($total / $i) . " results per search\n";
		
		push @benchmarks, [ "Closest, $count, <100km", $$benchmark[1], $$benchmark[0], ($total / $i) ];
	}
}



if (1) { # Search, radius 1000, n results
	push @benchmarks, undef; # blank line
	foreach my $count ( 1, 3, 10, 33, 100, 330, 1_000 ) {
		print "\nSearch( point , { radius=>$radius, max_results=>$count, no_search_point_in_results } )\n";
		my $i=0;
		my $total = 0;
		my $max = scalar @search;
		$benchmark = benchmark_code( $MIN_TEST_SECONDS, sub { 
		                                    my $search_point = $search[($i++ % $max)]; 
		                                    my $results = $index->Search(
		                                                                  $search_point, 
		                                                                  {
		                                                                    tile_adjust=>$tile_adjust, 
		                                                                    radius=>100_000, 
		                                                                    max_results=>$count, 
		                                                                    sort_results=>1, 
		                                                                    post_condition => $no_search_point_in_results
		                                                                  }
		                                                                );
		                                    $total += (defined $results) ? scalar(@$results) : 0;
		                                   } );
		print "Average of " . ($total / $i) . " results per search\n";
		
		push @benchmarks, [ "Search, sort, max $count, <100km", $$benchmark[1], $$benchmark[0], ($total / $i) ];
	}
}



push @benchmarks, undef; # blank line



if (1) { # Search, n results
	push @benchmarks, undef; # blank line
	foreach my $count ( 1, 1_000 ) {
		print "\nSearch( point , { radius=>$radius, sort_results=>1, max_results=>$count, no_search_point_in_results } )\n";
		my $i=0;
		my $total = 0;
		my $max = scalar @search;
		$benchmark = benchmark_code( $MIN_TEST_SECONDS, sub { 
		                                    my $search_point = $search[($i++ % $max)]; 
		                                    my $results = $index->Search(
		                                                                  $search_point, 
		                                                                  {
		                                                                    tile_adjust=>$tile_adjust, 
		                                                                    max_results=>$count, 
		                                                                    sort_results=>1, 
		                                                                    post_condition => $no_search_point_in_results
		                                                                  }
		                                                                );
		                                    $total += (defined $results) ? scalar(@$results) : 0;
		                                   } );
		print "Average of " . ($total / $i) . " results per search\n";
		
		push @benchmarks, [ "Linear search, sort, max $count", $$benchmark[1], $$benchmark[0], ($total / $i) ];
	}
}



push @benchmarks, undef; # blank line



if (1) { # SearchByBounds, normal results
	print "\nSearchByBounds( ... )\n";
	my $i=0;
	my $total = 0;
	my $max = scalar @search;
	$benchmark = benchmark_code( $MIN_TEST_SECONDS, sub {
	                                    my $p0 = $search[($i++ % $max)];
	                                    my $p1 = $search[($i++ % $max)];
	                                    my $w = $$p0{lon};
	                                    my $s = $$p0{lat};
	                                    my $e = $$p1{lon};
	                                    my $n = $$p1{lat};
	                                    ( $n, $s ) = ( $s, $n ) if ( $n < $s );
	                                    my $results = $index->SearchByBounds(
	                                                                          [ $w, $s, $e, $n ],
	                                                                          { tile_adjust=>$tile_adjust }
	                                                                        );
	                                    $total += (defined $results) ? scalar(@$results) : 0;
	                                  } );
	
	print "Average of " . ($total / ($i / 2)) . " results per search\n";
	
	push @benchmarks, [ "SearchByBounds, normal", $$benchmark[1], $$benchmark[0], ($total / $i) ];
}



if (1) { # SearchByBounds, quick results
	print "\nSearchByBounds( ... , { quick_results } )\n";
	my $i=0;
	my $total = 0;
	my $max = scalar @search;
	$benchmark = benchmark_code( $MIN_TEST_SECONDS, sub {
	                                    my $p0 = $search[($i++ % $max)];
	                                    my $p1 = $search[($i++ % $max)];
	                                    my $w = $$p0{lon};
	                                    my $s = $$p0{lat};
	                                    my $e = $$p1{lon};
	                                    my $n = $$p1{lat};
	                                    ( $n, $s ) = ( $s, $n ) if ( $n < $s );
	                                    my $results = $index->SearchByBounds(
	                                                                          [ $w, $s, $e, $n ],
	                                                                          { tile_adjust=>$tile_adjust, quick_results=>1 }
	                                                                        );
	                                    if (defined $results) {
	                                      foreach my $subarray ( @$results ) {
	                                        if (defined $subarray && ref $subarray) {
	                                          $total += scalar(@$subarray);
	                                        }
	                                      }
	                                    }
	                                  } );
	print "Average of " . ($total / ($i / 2)) . " results per search\n";
	
	push @benchmarks, [ "SearchByBounds, quick", $$benchmark[1], $$benchmark[0], ($total / $i) ];
}



if (1) { # SearchByBounds, normal results, 1 degree
	print "\nSearchByBounds( ... , { quick_results } )  (one degree)\n";
	my $i=0;
	my $total = 0;
	my $max = scalar @search;
	$benchmark = benchmark_code( $MIN_TEST_SECONDS, sub {
	                                    my $p0 = $search[($i++ % $max)];
	                                    my $w = $$p0{lon};
	                                    my $s = $$p0{lat};
	                                    my $e = $w + 1;
	                                    my $n = $s + 1;
	                                    ( $s, $n ) = ( $s-1, $s ) if ( $n > 90.0 );
	                                    ( $e, $w ) = ( $e-1, $e ) if ( $e >= 180.0 );
	                                    my $results = $index->SearchByBounds(
	                                                                          [ $w, $s, $e, $n ],
	                                                                          { tile_adjust=>$tile_adjust }
	                                                                        );
	                                    $total += (defined $results) ? scalar(@$results) : 0;
	                                  } );
	print "Average of " . ($total / ($i / 2)) . " results per search\n";
	
	push @benchmarks, [ "SearchByBounds, normal, 1 deg", $$benchmark[1], $$benchmark[0], ($total / $i) ];
}



if (1) { # SearchByBounds, quick results
	print "\nSearchByBounds( ... , { quick_results } )  (one degree)\n";
	my $i=0;
	my $total = 0;
	my $max = scalar @search;
	$benchmark = benchmark_code( $MIN_TEST_SECONDS, sub {
	                                    my $p0 = $search[($i++ % $max)];
	                                    my $w = $$p0{lon};
	                                    my $s = $$p0{lat};
	                                    my $e = $w+1;
	                                    my $n = $s+1;
	                                    ( $s, $n ) = ( $s-1, $s ) if ( $n > 90.0 );
	                                    ( $e, $w ) = ( $e-1, $e ) if ( $e >= 180.0 );
	                                    my $results = $index->SearchByBounds(
	                                                                          [ $w, $s, $e, $n ],
	                                                                          { tile_adjust=>$tile_adjust, quick_results=>1 }
	                                                                        );
	                                    if (defined $results) {
	                                      foreach my $subarray ( @$results ) {
	                                        if (defined $subarray && ref $subarray) {
	                                          $total += scalar(@$subarray);
	                                        }
	                                      }
	                                    }
	                                  } );
	print "Average of " . ($total / ($i / 2)) . " results per search\n";
	
	push @benchmarks, [ "SearchByBounds, quick, 1 deg", $$benchmark[1], $$benchmark[0], ($total / $i) ];
}




# END benchmarks



# .----------------------------.
# | Show current configuration |
# '----------------------------'


print "\n\n\nEnd of tests\n\n\n\n" . '-'x80 . "\n\n\n\n";


ShowConfiguration($index);

print "\n";


# .-----------------------.
# | Show index statistics |
# '-----------------------'

my $final_points_memory = Devel::Size::total_size(\@points);
my $final_index_memory  = Devel::Size::total_size($index);

print "Number of points: ".commify(scalar(@points))."\n";
print "\n";
print "Before searching:\n";
printf( "    Size of points:   %s\n", PrettyPrint($initial_points_memory));
printf( "    Size of index*:   %s\n", PrettyPrint($initial_index_memory) );
print "\n";
print "After searching:\n";
printf( "    Size of points:   %s\n", PrettyPrint($final_points_memory));
printf( "    Size of index*:   %s\n", PrettyPrint($final_index_memory) );
print "\n";
print "* includes size of points\n";

print "\n";

my @stats = $index->GetStatistics();

print "\n";
print "Index statistics:\n";
print "\n";
printf( "%5s  %10s  %9s  %9s  %9s\n", 'Level', 'Used tiles', 'Min./tile', 'Max./tile', 'Avg./tile' );
printf( "%5s  %10s  %9s  %9s  %9s\n", '-'x5,   '-'x10,   '-'x9,       '-'x9,       '-'x9 );
foreach my $_stats (@stats) {
	printf( "%5i  %10i  %9i  %9i  %9.1f\n", $$_stats{level}, $$_stats{tiles}, $$_stats{min_tile_points}, $$_stats{max_tile_points}, $$_stats{avg_tile_points} );
}

print "\n";



# .------------------------.
# | Show benchmark results |
# '------------------------'

printf("%30s %10s %10s %10s %4s\n", 'Description', 'Avg. res.', 'Count/Sec.', 'Count', 'Sec.' );
printf("%30s %10s %10s %10s %4s\n", '-'x30, '-'x10, '-'x10, '-'x10, '-'x4 );
foreach my $test (@benchmarks) {
	if (defined $test) {
		if (defined $$test[3]) {
			if ($$test[1]) {
				printf("%30s %10.2f %10.2f % 10i %4.1f\n", $$test[0], $$test[3], $$test[2] / $$test[1], $$test[2], $$test[1] );
			} else {
				printf("%30s %10.2f %10s % 10i %4.1f\n",   $$test[0], $$test[3], 'unknown',             $$test[2], $$test[1] );
			}
		} else {
			if ($$test[1]) {
				printf("%30s %10s %10.2f % 10i %4.1f\n", $$test[0], '',        $$test[2] / $$test[1], $$test[2], $$test[1] );
			} else {
				printf("%30s %10s %10s % 10i %4.1f\n",   $$test[0], '',        'unknown',             $$test[2], $$test[1] );
			}
		}
	} else {
		print "\n";
	}
}

my $duration = ($MIN_TEST_SECONDS > 1) ? "$MIN_TEST_SECONDS seconds" : "$MIN_TEST_SECONDS second";
print <<EOF;

For searches above, tile_adjust was $tile_adjust
Each test was run for at least $duration.

For index creation line:
  'Count/Sec.' is the number of points indexed per second
  'Count' is the total number of points indexed across all tests
  'Sec.' is the number of seconds taken to run all tests

For other lines:
  'Avg. res.' is the average number of points returned by each search
  'Count/Sec.' is the number of searches per second
  'Count' is the total number of searches performed
  'Sec.' is the number of seconds taken to run all searches
EOF

exit;



# .-------------------.
# | Support functions |
# '-------------------'


# Print the index's configuration
sub ShowConfiguration($) {
	my ($index) = @_;
	my %config = $index->GetConfiguration();
	print "Running configuration:\n";
	print "    Key type:   $config{key_type}\n";
	print "    Code type:  $config{code_type}\n";
	my $equatorial_tile_width = $config{equatorial_circumference} / ( 2**$config{levels} );
	print "    Levels:     $config{levels}  (approximately ".int($equatorial_tile_width + 0.5)." meter wide tiles at equator)\n";
	print "    Index size: ".commify($config{size})." points\n";
	if ($POINT_AREA) {
		# Square region
		
		my $point_area_meters = int( ( $config{equatorial_circumference} * $POINT_AREA ) / 360.0 + 0.5);
		my $pp_point_area_meters = commify(int($point_area_meters));
		
		print "    Point area: Points distributed over\n";
		print "                $POINT_AREA x $POINT_AREA degrees\n";
		print "                $pp_point_area_meters x $pp_point_area_meters meters\n";
		
		my $points_per_square_km = commify( $config{size} / ( ($point_area_meters/1000) * ($point_area_meters/1000) ) );
		print "                In point area:\n";
		print "                    $points_per_square_km points per square km\n";
		
		my $min_tile_area   = $equatorial_tile_width**2;
		my $point_area_area = $point_area_meters**2;
		my $min_tile_points = $config{size} / $point_area_area * $min_tile_area;
		print "                    $min_tile_points per tile at full index depth\n";
	} else {
		# Entire planet
		
		my $planet_area = 4 * 3.14159265358979 * ( $config{planetary_radius}**2 );
		my $planet_area_square_km = $planet_area / 1_000_000;
		
		print "    Point area: Points distributed over entire planet\n";
		print "                ".commify(int($planet_area_square_km))." square km\n";
		
		my $points_per_square_km = commify($config{size} / $planet_area_square_km);
		print "                $points_per_square_km points per square km\n";
		
		my $min_tile_area = $planet_area / ( 2**($config{levels} - 1) );
		my $min_tile_points = $config{size} / $planet_area * $min_tile_area;
		print "                $min_tile_points per tile at full index depth\n";
	}
}


# Pretty-print a number with commas between thousands
# From the Perl Cookbook
sub commify($) {
	my $text = reverse $_[0];
	$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
	return scalar reverse $text;
}


#.Pretty print a number as a number of bytes and as a shorthand (e.g. MB)
sub PrettyPrint($) {
	my ($n) = @_;
	
	my $v = $n;
	my $u = 0;
	
	while ($v >= 1024) {
		$v /= 1024;
	  $u++;
		last if ($u == 4);
	}
	
	$v = ( $v == int $v ) ? $v : sprintf("%.2f", $v);
	
	$u = ($u == 0) ? 'B'
	   : ($u == 1) ? 'kB'
	   : ($u == 2) ? 'MB'
	   : ($u == 3) ? 'GB'
	   :             'TB';
	
	return sprintf("%14s B ( %7.2f %s )", commify($n), $v, $u );
}


# Run a block of code multiple times for at least the specified number of seconds
sub benchmark_code($$) {
	my ($MIN_TEST_SECONDS, $_code) = @_;
	my $count = 0;
	my $t0 = Time::HiRes::time();
	my $t_end = $t0 + $MIN_TEST_SECONDS;
	my $t1;
	do {
		&$_code();
		$t1 = Time::HiRes::time();
		$count++;
	} until ($t1 >= $t_end );
	my $duration = $t1 - $t0;
	print "$count iterations over $duration seconds, ".($count/$duration)." iterations per second\n";
	return [ $count, $duration ];
}
