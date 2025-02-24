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

if (! libpng_supports ('eXIf')) {
    plan skip_all => "This libpng doesn't support the eXIf chunk"
}
my $libpng_version = Image::PNG::Libpng::get_libpng_ver ();
my ($x, $major, $minor) = ($libpng_version =~ m!([0-9]+)\.([0-9]+)\.([0-9]+)!);
if ($major >= 6 && $minor >= 47) {
    plan skip_all => "Faulty libpng does not handle eXif";
}

# This file doesn't contain an exif chunk

my $png = read_png_file ("$Bin/test.png");
my $noexif = $png->get_eXIf ();
ok (! defined $noexif, "Got undefined from file with no exif");

# Copy the file, add an exif chunk

my $wpng = copy_png ($png);
my $exif = "MM random garbage";
$wpng->set_eXIf ($exif);

# Now write the file out, then read it back in.

my $file = 'exif.png';
my $rpng = round_trip ($wpng, $file);

# Check the exif chunk of the read-in file. 

# This produces a warning "libpng warning: eXIf: duplicate" with
# libpng 1.6.37 due to a bug in libpng.

my $roundtrip = $rpng->get_eXIf ();
is ($roundtrip, $exif, "Round trip of eXIf chunk");
done_testing ();
exit;
