use warnings;
use strict;
use Test::More;
use FindBin;
use Image::PNG::Const ':all';
use Image::PNG::Libpng ':all';
plan skip_all => "sCAL is not supported by your libpng" unless libpng_supports ('sCAL');

# I don't have an example PNG with an sCAL chunk. So this is tested by
# writing and then reading the file.

my $file = "$FindBin::Bin/sCAL.png";
my @rows = (pack ("CCC", 0xFF, 0, 0));
my $png = create_write_struct ();
$png->set_IHDR ({width => 1, height => 1, bit_depth => 8,
		color_type => PNG_COLOR_TYPE_RGB});
$png->set_rows (\@rows);
my %inputs = (unit => PNG_SCALE_METER, width => "100", height => "100");
$png->set_sCAL (\%inputs);
$png->write_png_file ($file);
my $png2 = read_png_file ($file);
my $scal = $png2->get_sCAL ();
is_deeply ($scal, \%inputs);
if (-f $file) {
    unlink ($file);
}
done_testing ();
