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
use Image::PNG::Const ':all';

BEGIN: {
    use lib "$Bin";
    use IPNGLT;
};

if (libpng_supports ('READ_EXPAND')) {
    my $png = read_png_file ("$Bin/tantei-san.png",
			     transforms => PNG_TRANSFORM_EXPAND);
    my $ihdr = $png->get_IHDR ();
    is ($ihdr->{color_type}, PNG_COLOR_TYPE_RGB);
    is ($ihdr->{bit_depth}, 8);
}
if (libpng_supports ('READ_EXPAND_16')) {
    my $png2 = read_png_file ("$Bin/tantei-san.png",
			      transforms => PNG_TRANSFORM_EXPAND |
			      PNG_TRANSFORM_EXPAND_16);
    my $ihdr2 = $png2->get_IHDR ();
    is ($ihdr2->{color_type}, PNG_COLOR_TYPE_RGB);
    is ($ihdr2->{bit_depth}, 16);
}

done_testing ();
