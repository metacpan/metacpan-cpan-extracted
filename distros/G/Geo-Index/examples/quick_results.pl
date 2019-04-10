#!/usr/bin/perl

use strict;
use warnings;

use Geo::Index;

sub LoadPoints();
my $_results;


print "Loading points\n";

# Load points
my $_points = LoadPoints();

# Create and populate index
my $index = Geo::Index->new( $_points, { levels=>20 } );



print "\nRunning normal search (1,000 km radius) around 10 points\n\n";

# Initialize the random number generator so we get
# the same set of points for both set of runs.
srand 0;

# Try 10 points...
for (my $i=0; $i<10; $i++) {
	
	# Choose search point
	my $_point = $$_points[rand(@$_points)];
	print "\t$$_point{name}:\n";
	
	# Run search
	my $_results = $index->Search( $_point, { sort_results=>1, radius=>1_000_000, pre_condition=>sub { my ($rp, $sp, $d)=@_; return ($rp!=$sp); } } );
	
	# The results returned for normal searches is a reference to a list of points
	# e.g. [ POINT, POINT, POINT ]
	
	# Display results
	
	if (defined $_results) {
		# We got results
		
		# Loop through the results...
		foreach my $p1 (@$_results) {
			# We're looking at a single point
			# Display its name and distance
			printf("\t\t$$p1{name}: %i km\n", int($$p1{search_result_distance} / 1000));
		}
	}
	
	print "\n";
}
print "\n\n";




print "\nRunning quick search (1,000 km radius) around the same 10 points\n\n";

# Initialize the random number generator so we get
# the same set of points for both set of runs.
srand 0;

# Try 10 points...
for (my $i=0; $i<10; $i++) {
	
	# Choose search point
	my $_point = $$_points[rand(@$_points)];
	print "\t$$_point{name}:\n";
	
	# Run Search
	my $_results = $index->Search( $_point, { quick_results=>1, radius=>1_000_000 } );
	
	# The results returned for quick searches is a reference to a list of lists of points
	# some of which might be undefined
	# e.g. [ [ POINT, POINT ], undef, [ POINT ], [ POINT, POINT, POINT ] ]
	
	# Display results
	
	# Loop through result set...
	foreach my $_set (@$_results) {
		# Skip empty result sets
		next unless (defined $_set);
		
		# Loop through points in result set
		foreach my $p1 (@$_set) {
			# We're looking at a single point
			# Since no distances are computed in quick mode
			# we'll just display its name
			print "\t\t$$p1{name}\n";
		}
	}
	print "\n";
}
print "\n\n";



# All other searches in this example work the same way
# Only the search parameters change


print "\nFinding points within 3,000 km of the north pole\n\n";

# Run search
$_results = $index->Search( [ 90, 0 ], { sort_results=>1, radius=>3_000_000 } );

# Display results
if (defined $_results) {
	foreach my $_point (@$_results) {
		printf("\t$$_point{name}: %i km\n", int($$_point{search_result_distance} / 1000));
	}
}
print "\n";


print "\nFinding points within 3,000 km of the north pole (quick results)\n\n";

# Run search
$_results = $index->Search( [ 90, 0 ], { quick_results=>1, radius=>3_000_000 } );

# Display results
foreach my $_set (@$_results) {
	next unless (defined $_set);
	foreach my $_point (@$_set) {
		print "\t$$_point{name}\n";
	}
}
print "\n";




print "\nFinding points within 5,000 km of the south pole\n\n";

# Run search
$_results = $index->Search( [ -90, 180 ], { sort_results=>1, radius=>5_000_000 } );

# Display results
if (defined $_results) {
	foreach my $_point (@$_results) {
		printf("\t$$_point{name}: %i km\n", int($$_point{search_result_distance} / 1000));
	}
}
print "\n";


print "\nFinding points within 5,000 km of the south pole (quick results)\n\n";

# Run search
$_results = $index->Search( [ -90, 180 ], { quick_results=>1, radius=>5_000_000 } );

# Display results
foreach my $_set (@$_results) {
	next unless (defined $_set);
	foreach my $_point (@$_set) {
		print "\t$$_point{name}\n";
	}
}
print "\n";







# Core Perl modules, used to build the filename
use File::Spec;
use File::Basename;
use Cwd;

sub LoadPoints() {
	my @points = ();
	
	# Determine sample data's filename
	my $file = File::Spec->catdir(
	             File::Basename::dirname( Cwd::abs_path($0) ),
	             'cities.txt'
	           );
	
	# Make sure the data file exists
	unless ( -e $file ) {
		print STDERR "Data file '$file' not found.\n";
		exit;
	}
	
	# Load the sample data
	open IN, $file;
	
	# Loop through the file's lines...
	while (my $line = <IN>) {
		
		# Remove trailine newline
		chomp $line;
		
		# Each line is tab-delimited into two text and two numeric fields.
		my ($country, $city, $lat, $lon) = split /\t/, $line;
		
		# Clean up leading and trailing spaces
		$country =~ s/\s+$//;
		$country =~ s/^\s+//;
		$city =~ s/^\s+//;
		$city =~ s/\s+$//;
		
		# Create a point for this line
		# Note that this is a 'proper' point, namely a hash with 
		# entries for 'lat' and 'lon'.
		push @points, { lat=>$lat, lon=>$lon, name=>($city) ? "$city, $country" : $country };
		
	}
	
	# Close the data file
	close IN;
	
	return \@points;
}
