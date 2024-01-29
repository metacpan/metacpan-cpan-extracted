# Test "get_internals"

use warnings;
use strict;
use Test::More;
use FindBin '$Bin';
use Image::PNG::Libpng ':all';
my $png = read_png_file ("$Bin/gecko-1200-gray8.png");
my ($x, $y) = get_internals ($png);
ok ($x);
ok ($y);
done_testing ();
exit;

