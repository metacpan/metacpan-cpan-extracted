#!/usr/bin/perl

use strict;
use warnings;

use Geo::Index;

sub LoadPoints();


# Load points
my $_points = LoadPoints();

# Create and populate index
my $index = Geo::Index->new( $_points, { levels=>20 } );



print "Running Search(...), Closest(...), and Farthest(...) for all points\n\n";

# Loop through all points in alphabetical order:
foreach my $point ( sort { $$a{name} cmp $$b{name} } @$_points ) {
	my $_results;
	
	print "Search(...):\n";
	
	# Run a simple search
	#
	# The search parameters are:
	#
	#     sort_results => 1
	#     Sort results by their distance from the search point
	#
	#     max_results => 0
	#     Return an unlimited number of points (i.e. all points in index)
	#
	#     radius => Geo::Index::ALL
	#     Search is world-wide (normally this option's value would be the search radius in meters)
	#
	#     pre_condition=>sub { my ($rp, $sp, $d)=@_; return ($rp!=$sp); }
	#     Filter to exclude the search point ($sp) from the results
	#
	$_results = $index->Search( $point, { sort_results=>1, max_results=>0, radius=>Geo::Index::ALL, pre_condition=>sub { my ($rp, $sp, $d)=@_; return ($rp!=$sp); } } );
	
	$_results = [ ] unless (defined $_results);
	printf( "Got %i result%s\n", scalar @$_results, (scalar(@$_results) > 1) ? 's' : '' );
	printf( "% 60s  |  %s (%i km)\n", $$point{name}, "$$_results[0]{name}:", int($$_results[0]{search_result_distance} / 1000) );
	printf( "% 60s  |  %s (%i km)\n", $$point{name}, "$$_results[-1]{name}:", int($$_results[-1]{search_result_distance} / 1000) );
	
	print "Closest(...):\n";
	
	$_results = $index->Closest( $point );
	
	$_results = [ ] unless (defined $_results);
	printf( "Got %i result%s\n", scalar @$_results, (scalar(@$_results) > 1) ? 's' : '' );
	printf( "% 60s  |  %s (%i km)\n", $$point{name}, "$$_results[0]{name}:", int($$_results[0]{search_result_distance} / 1000) );
	
	print "Farthest(...):\n";
	
	$_results = $index->Farthest( $point );
	
	$_results = [ ] unless (defined $_results);
	printf( "Got %i result%s\n", scalar @$_results, (scalar(@$_results) > 1) ? 's' : '' );
	printf( "% 60s  |  %s (%i km)\n", $$point{name}, "$$_results[0]{name}:", int($$_results[0]{search_result_distance} / 1000) );
	
	print "\n\n".('-'x125)."\n\n";
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
