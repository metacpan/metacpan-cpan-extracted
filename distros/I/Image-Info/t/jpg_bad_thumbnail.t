use strict;
use warnings;

use FindBin qw($Bin);
use Test::More tests => 3;

use Image::Info qw(image_info);

my @i = image_info("$Bin/../img/bad-thumbnail.jpg");
is @i, 2, 'Two images found';
ok !exists $i[0]->{error}, 'no error on main image' or diag "Got Error: $i[0]->{error}";
like $i[1]->{error}, qr/^SOI missing/, 'error on thumbnail image';
