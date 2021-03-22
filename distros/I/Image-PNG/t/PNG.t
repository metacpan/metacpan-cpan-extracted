# This file contains tests for the PNG.pm module (the simplified OO
# version of PNG access).

use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

use Image::PNG;

# "Supports" is imported to test whether the underlying library
# supports iTXt chunks and skip some of the tests if not.

use Image::PNG::Libpng qw/libpng_supports/;

my $png = Image::PNG->new ({verbosity => undef});
my $file = "$Bin/test.png";
$png->read ($file);

# Test the reading of the PNG file's header.

ok ($png->width () == 100, "oo-width");
ok ($png->height () == 100, "oo-height");
ok ($png->color_type () eq 'RGB', "oo colour type");
ok ($png->bit_depth () == 8, "oo bit depth");

# Test writing out the file.

my $out_file = "$Bin/out.png";
if (-f $out_file) {
    unlink $out_file or die $!;
}
$png->write ($out_file);
ok (-f $out_file, "Write output file");
eval {
    unlink ($out_file) or die $!;
};

# Test the documentation's claim that a PNG with no time returns the
# undefined value.

my $png2 = Image::PNG->new ({verbosity => undef});
my $time2 = $png2->time ();
ok (! defined $time2, "Time () is not defined for empty PNG");
my $time = $png->time ();
ok (! defined $time, "Time () is not defined for PNG with no time");

# Test for non-existent file

my $pngr = Image::PNG->new();
eval {
    $pngr->read("abcdef");
};
ok ($@, "Error trying to read non-existent file");

done_testing ();

# Local Variables:
# mode: perl
# End:
