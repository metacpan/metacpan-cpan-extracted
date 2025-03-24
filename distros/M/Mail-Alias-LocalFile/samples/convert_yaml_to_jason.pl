#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use YAML::XS qw(LoadFile);
use JSON::XS;
use feature 'say';

# Check if the input file exists
my $input_file = shift;
die "Error: File '$input_file' not found\n" unless -e $input_file;

my ( $name, $path, $suffix ) = fileparse( $input_file, qr/\.[^.]*/ );
# output file name is same as input filename with json as suffix
my $output_file = $path . $name . '.json'; 

# Load the YAML file into a hash reference
print "Loading YAML from $input_file...\n";
my $aliases;
eval {
    $aliases = LoadFile($input_file);
};
if ($@) {
    die "Error parsing YAML file: $@\n";
}

# Create a JSON encoder object with pretty formatting
my $json = JSON::XS->new->pretty->utf8;

# Convert the hash reference to JSON and write to file
print "Writing JSON to $output_file...\n";

open my $fh, '>', $output_file or die "Cannot open $output_file for writing: $!\n";
print $fh $json->encode($aliases);
close $fh;

print "Conversion completed successfully.\n";
