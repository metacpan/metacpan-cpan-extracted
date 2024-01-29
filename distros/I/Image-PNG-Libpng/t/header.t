use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Image::PNG::Libpng ':all';

BEGIN: {
    use lib "$Bin";
    use IPNGLT;
};

my $png = read_png_file ("$Bin/gecko-1200-gray8.png");
cmp_ok ($png->get_image_width (), '==', 1116, "get_image_width");
cmp_ok ($png->height (), '==', 624, "height method");
cmp_ok ($png->width (), '==', 1116, "width method");
cmp_ok ($png->get_image_height (), '==', 624, "get_image_height");

done_testing ();
