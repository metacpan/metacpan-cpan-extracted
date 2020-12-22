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

# There are too many different things that can go wrong
# with the old libpngs.

skip_old (); 

# tantei-san.png is a 256-color paletted grayscale, qrpng is a 1 bit
# image, ../examples/life_* is a grayscale image in an RGB PNG file.

for my $f (qw!tantei-san qrpng x-life!) {
    my $file = "$Bin/$f.png";
    $file =~ s!x-!../examples/!;
    die unless -f $file;
    my $wpng = any2gray8 ($file);
    ok ($wpng, "Returned a value");
    my $gray8 = "$Bin/gray8-$f.png";
    rmfile ($gray8);
    $wpng->write_png_file ($gray8);
    ok (! png_compare ($file, $gray8), "Image data is identical");
    rmfile ($gray8);
}

done_testing ();
