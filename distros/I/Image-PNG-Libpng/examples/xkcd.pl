#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Image::PNG::Libpng ':all';
use Image::PNG::Const ':all';

my $file = 'life.png';
print "Size before: ", -s $file, "\n";
my $png = create_reader ($file);
$png->read_info ();
$png->set_rgb_to_gray ();
if ($png->get_rgb_to_gray_status ()) {
    print "The image contained non-gray pixels.\n";
}
else {
    print "The image was grayscale already.\n";
}
$png->read_image ();
$png->read_end ();
my $wpng = $png->copy_png ();
my $ihdr = $wpng->get_IHDR ();
$ihdr->{color_type}  = PNG_COLOR_TYPE_GRAY;
$wpng->set_IHDR ($ihdr);
my $after = "life-gray.png";
$wpng->write_png_file ($after);
print "Size after: ", -s $after, "\n";

if (! png_compare ($file, $after)) {
    print "The two files contain exactly the same image data.\n";
}
else {
    print "The two files contain different image data.\n";
}
