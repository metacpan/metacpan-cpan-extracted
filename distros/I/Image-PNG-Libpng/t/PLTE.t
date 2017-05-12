use warnings;
use strict;
use FindBin;
use Image::PNG::Libpng;
use Test::More tests => 3;

my $file_name = "$FindBin::Bin/tantei-san.png";
my $png = Image::PNG::Libpng::create_read_struct ();
open my $file, "<:raw", $file_name or die $!;
Image::PNG::Libpng::init_io ($png, $file);
#print "Reading PNG.\n";
Image::PNG::Libpng::read_png ($png);
#print "Getting rows.\n";
my $colors = Image::PNG::Libpng::get_PLTE ($png);
#exit;
# for my $i (0..$#$colors) {
#     my $color = $colors->[$i];
#     print "$i: Red: $color->{red} green: $color->{green} blue: $color->{blue}\n";
# }
ok ($colors->[10]->{red} == 10);
ok ($colors->[20]->{green} == 20);
ok ($colors->[100]->{blue} == 100);
close $file or die $!;

# Local Variables:
# mode: perl
# End:
