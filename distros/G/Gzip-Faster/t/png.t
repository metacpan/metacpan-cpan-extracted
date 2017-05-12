# This tests our "deflate" against libpng. */

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
use Gzip::Faster ':all';

my @modules = ('Digest::CRC', "Image::PNG::Libpng ':all'");
for my $module (@modules) {
    eval "use $module";
    if ($@) {
	plan skip_all => "These tests require $module";
    }
}

my $width = 100;
my $height = 100;

my $width_bytes = int (($width + 7) / 8);

# The first \0 is the filter bit, see
# http://stackoverflow.com/questions/10134150/libpng-warning-ignoring-bad-adaptive-filter-type#31304752

my $data = ("\0" . "A" x $width_bytes) x $height; 

my $pngdata = make_bw_png ($data, $width, $height);
my $png;
eval {
    $png = read_from_scalar ($pngdata);
};
ok (! $@, "No errors reading homemade png data");
if ($@) {
    note "Got error $@";
}
ok ($png, "Got a parsed PNG data out");

SKIP: {
    skip "No valid PNG structure", 2 unless defined $png;
    my $ihdr = $png->get_IHDR ();
    ok ($ihdr->{width} == $width, "width OK");
    ok ($ihdr->{height} == $height, "height OK");
# Look at the image.
#    open my $out, ">:raw", "monkey.png" or die $!;
#    print $out $pngdata;
#    close $out or die $!;
};

done_testing ();

# This PNG writing code was taken from Image-PNG-Write-BW-0.01 

# https://metacpan.org/source/ANALL/Image-PNG-Write-BW-0.01/lib/Image/PNG/Write/BW.pm

sub make_bw_png
{
    my ($data, $width, $height) = @_;
    my $png_signature = pack ("C8", 137, 80, 78, 71, 13, 10, 26, 10);
    my $png_iend = make_png_chunk ("IEND", "");
    my $ihdr = make_ihdr ($width, $height, 1, 0, 0, 0, 0);
    return join ("", $png_signature, $ihdr,
		 make_png_chunk ("IDAT", deflate ($data)),
		 $png_iend);
}

sub make_ihdr
{
    return make_png_chunk ("IHDR", pack ("NNCCCCC", @_));
}

sub make_png_chunk
{
    my ($type, $data) = @_;
    my $ctx = Digest::CRC->new (type => "crc32");
    $ctx->add ($type);
    $ctx->add ($data);
    my $crc =  pack ("N", $ctx->digest);
    my $len = pack ("N", length ($data));
    return join ("", $len, $type, $data, $crc);
}

