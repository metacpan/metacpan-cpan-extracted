#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Image::PNG::Libpng ':all';
my $png = read_png_file ('../t/tantei-san.png');
# Get all valid chunks
my $valid = $png->get_valid ();
my @valid_chunks = sort grep {$valid->{$_}} keys %$valid;
print "Valid chunks are ", join (", ", @valid_chunks), "\n";
# Print image information
my $header = $png->get_IHDR ();
for my $k (keys %$header) {
    if ($k eq 'color_type') {
	print "$k: " . color_type_name ($header->{$k}) . "\n";
    }
    else {
	print "$k: $header->{$k}\n";
    }
}
my $wpng = $png->copy_png ();
$wpng->write_png_file ('new.png');

