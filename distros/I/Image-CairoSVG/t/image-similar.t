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

use Cairo;
use Image::CairoSVG;

eval "use Image::Similar;use Image::PNG::Libpng ':all';";

if ($@) {
    plan (skip_all => "Could not load required modules: $@");
}

for my $f (qw/Technical_college Church/) {
    my $surface = Cairo::ImageSurface->create ('argb32', 400, 400);
    my $cairosvg2 = Image::CairoSVG->new (
	surface => $surface,
    );
    my $stem = "$Bin/$f";
    my $file = "$stem.svg";
    $cairosvg2->render ($file);
    my $tempout = "$stem-out.png";
    $surface->write_to_png ($tempout);
    ok (-f $tempout);
    my $orig_file = "$stem.png";
    my $orig = read_png_file ($orig_file);
    my $orig_is = Image::Similar::load_image_libpng ($orig);
    my $rendered = read_png_file ($tempout);
    my $rendered_is = Image::Similar::load_image_libpng ($rendered);
    my $diff = $orig_is->diff ($rendered_is);
    print "$diff\n";
    cmp_ok ($diff, '<', 0.1, "$orig_file looks like $tempout");
};

done_testing ();
