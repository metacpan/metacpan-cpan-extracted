use warnings;
use strict;
use Test::More;
use FindBin;
use Image::PNG::Libpng ':all';
use Data::Dumper;

my $file = 's38i3p04';
my $ffile = "$FindBin::Bin/libpng/$file.png";
my $png = read_png_file ($ffile);
ok ($png);
#    print Dumper ($png);
my $sbit = $png->get_sBIT ();
ok ($sbit);
is ($sbit->{red}, 4);
is ($sbit->{green}, 4);
is ($sbit->{blue}, 4);
done_testing ();
