#!/usr/bin/perl

use strict;
use warnings;

use Geo::Index;

sub LoadPoints();
my $_results;

# Load points
my $_points = LoadPoints();

# Create and populate index
my $index = Geo::Index->new( $_points, { levels=>20 } );


print "Trying bounding boxes that roughly covering areas:\n\n";


# Define the areas we'll be searching

# Test the limits
my %bad_lats     = ( north=>-20.0,    west=>-180.0,     south=>20.0,      east=>180.0     );  # Invalid: south > north
my %out_of_range = ( north=>91.0,     west=>-181.0,     south=>-91.0,     east=>181.0     );  # Invalid: all extrema out of bounds
my %max_range    = ( north=>90.0,     west=>-180.0,     south=>-90.0,     east=>180.0     );  # Entire planet

# Various regions
my %europe       = ( north=>66.58322, west=>-25.13672,  south=>36.17336,  east=>36.71631  );  # lat > 0, lon > 0
my %carribean    = ( north=>28.00410, west=>-86.24268,  south=>9.88769,   east=>-59.07898 );  # lat > 0, lon < 0
my %africa       = ( north=>37.85751, west=>-18.41309,  south=>-34.92197, east=>54.53613  );  # straddles equator and prime meridian
my %aus_nz       = ( north=>-9.53575, west=>112.14844,  south=>-47.29413, east=>-176.0    );  # lat < 0, straddles antimeridian
my %antarctica   = ( north=>-60.0,    west=>-180.0,     south=>-90.0,     east=>180.0     );  # south polar region
my %arctic       = ( north=>90.0,     west=>-180.0,     south=>60.0,      east=>180.0     );  # north polar region


# Define search options

my %options;
#%options = ( condition => sub { my ($p, $b, $u)=@_; return ( $$p{name} =~ /^[A-M]/ ); } );  # Only points starting with the letters A through M
%options = ( );


# Run the searches


print "\tBad latitudes (will fail):\n";
# Run the search
$_results = $index->SearchByBounds( \%bad_lats, \%options );
# Did we get any results?
if (defined $_results) {
	# We got results
	
	# Sort the returned points by name
	# and loop through them...
	foreach my $p (sort { $$a{name} cmp $$b{name} } @$_results) {
		# We're looking at a single point($p) 
		# that matched our search query.
		
		# Just print the point's name
		print "\t\t$$p{name}\n";
	}
}
print "\n";


# All other searches in this example work the same way
# Only the areas being checked change


print "\tOut of range (will fail):\n";
$_results = $index->SearchByBounds( \%out_of_range, \%options );
if (defined $_results) {
	foreach my $p (sort { $$a{name} cmp $$b{name} } @$_results) {
		print "\t\t$$p{name}\n";
	}
}
print "\n";



print "\tMax range (all points on globe):\n";
$_results = $index->SearchByBounds( \%max_range, \%options );
if (defined $_results) {
	foreach my $p (sort { $$a{name} cmp $$b{name} } @$_results) {
		print "\t\t$$p{name}\n";
	}
}
print "\n";



print "\tEurope:\n";
$_results = $index->SearchByBounds( \%europe, \%options );
if (defined $_results) {
	foreach my $p (sort { $$a{name} cmp $$b{name} } @$_results) {
		print "\t\t$$p{name}\n";
	}
	print "\n";
}



print "\tCaribbean:\n";
$_results = $index->SearchByBounds( \%carribean, \%options );
if (defined $_results) {
	foreach my $p (sort { $$a{name} cmp $$b{name} } @$_results) {
		print "\t\t$$p{name}\n";
	}
	print "\n";
}



print "\tAfrica:\n";
$_results = $index->SearchByBounds( \%africa, \%options );
if (defined $_results) {
	foreach my $p (sort { $$a{name} cmp $$b{name} } @$_results) {
		print "\t\t$$p{name}\n";
	}
	print "\n";
}



print "\tAustralia and New Zealand:\n";
$_results = $index->SearchByBounds( \%aus_nz, \%options );
if (defined $_results) {
	foreach my $p (sort { $$a{name} cmp $$b{name} } @$_results) {
		print "\t\t$$p{name}\n";
	}
	print "\n";
}



print "\tAntarctica:\n";
$_results = $index->SearchByBounds( \%antarctica, \%options );
if (defined $_results) {
	foreach my $p (sort { $$a{name} cmp $$b{name} } @$_results) {
		print "\t\t$$p{name}\n";
	}
	print "\n";
}



print "\tArctic:\n";
$_results = $index->SearchByBounds( \%arctic, \%options );
if (defined $_results) {
	foreach my $p (sort { $$a{name} cmp $$b{name} } @$_results) {
		print "\t\t$$p{name}\n";
	}
	print "\n";
}








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
