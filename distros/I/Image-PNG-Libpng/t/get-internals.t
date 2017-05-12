# Test "get_internals"

use warnings;
use strict;
use Test::More;
use FindBin;
use Image::PNG::Libpng ':all';
my $png = read_png_file ("$FindBin::Bin/tantei-san.png");
my ($x, $y) = get_internals ($png);
ok ($x);
ok ($y);
done_testing ();
exit;

