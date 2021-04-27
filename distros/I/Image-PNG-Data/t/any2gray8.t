use FindBin '$Bin';
use lib "$Bin";
use IPNGDT;

# There are too many different things that can go wrong
# with the old libpngs.

skip_old (); 

# duck-rabbit.png is a 16-color paletted image which is grayscale
# life.png is a grayscale image in an RGB PNG file.
# qrpng.png is a 1 bit black/white image
# tantei-san.png is a 256-color paletted grayscale

for my $f (qw!tantei-san qrpng life duck-rabbit!) {
    my $file = "$Bin/$f.png";
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
