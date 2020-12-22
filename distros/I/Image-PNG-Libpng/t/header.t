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

my $png = read_png_file ("$Bin/tantei-san.png");
cmp_ok ($png->get_image_width (), '==', 293, "get_image_width");
cmp_ok ($png->height (), '==', 281, "height method");
cmp_ok ($png->width (), '==', 293, "width method");
cmp_ok ($png->get_image_height (), '==', 281, "get_image_height");

done_testing ();
