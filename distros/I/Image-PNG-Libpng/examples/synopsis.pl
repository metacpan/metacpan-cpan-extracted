#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Image::PNG::Libpng ':all';
my $png = create_read_struct ();
open my $file, '<:raw', 'nice.png' or die $!;
$png->init_io ($file);
$png->read_png ();
close $file;
# Get all valid chunks
my $valid = $png->get_valid ();
my @valid_chunks = sort grep {$valid->{$_}} keys %$valid;
print "Valid chunks are ", join (", ", @valid_chunks), "\n";
# Print image information
my $header = $png->get_IHDR ();
for my $k (keys %$header) {
    print "$k: $header->{$k}\n";
}
