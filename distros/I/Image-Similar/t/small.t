# Test for an overflow with small images.

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
use Image::Similar 'load_image';
use Image::PNG::Libpng ':all';
my $img = read_png_file ("$Bin/images/zw.png");
my $is;
eval {
    $is = load_image ($img);
};
ok (! $@);
ok ($is);
# use Imager;
# my $img2 = Imager->new ();
# $img2->read (file => "$Bin/images/zw.png");
# my $is2;
# eval {
#     $is2 = load_image ($img2);
# };
# ok (! $@);
# ok ($is2);
done_testing ();
