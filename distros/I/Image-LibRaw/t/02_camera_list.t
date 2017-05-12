use strict;
use warnings;
use Test::More tests => 2;
use Image::LibRaw;

my $img = Image::LibRaw->new;
cmp_ok($img->camera_count, '>', 50);
my @list = $img->camera_list;
is scalar(@list), $img->camera_count;
