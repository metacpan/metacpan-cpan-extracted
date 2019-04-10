#!/usr/bin/perl

use Geo::Index;
use Geo::Gpx;

# Construct filename
use File::Spec; use File::Basename; use Cwd;
my $filename = File::Spec->catdir( File::Basename::dirname( Cwd::abs_path($0) ), 'cities.gpx' );

# Load GPX file
open $IN, $filename;
my $gpx = Geo::Gpx->new( input => $IN );
close $IN;

# Create empty index
my $index = Geo::Index->new( { levels=>20 } );

# Directly add parsed GPX waypoints to index
$index->IndexPoints( $gpx->{waypoints} );

# Define a region
my %central_america = ( north=>19, west=>-94, south=>6, east=>-77  );

# Define search options
my %options = ( );

# Search for points in region
print "Points in Central America:\n";
my $_results = $index->SearchByBounds( \%central_america, \%options );

# Display points in region
if (defined $_results) {
	foreach my $p (sort { $$a{name} cmp $$b{name} } @$_results) {
		print "\t$$p{name}\n";
	}
}
print "\n";
