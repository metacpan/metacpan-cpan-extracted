use warnings;
use strict;
use Test::More;
use Image::PNG::Libpng ':all';
use FindBin '$Bin';

BEGIN: {
    use lib "$Bin";
    use IPNGLT;
};

my $libpng_version = Image::PNG::Libpng::get_libpng_ver ();
my ($x, $major, $minor) = ($libpng_version =~ m!([0-9]+)\.([0-9]+)\.([0-9]+)!);
if ($major >= 6 && $minor >= 47) {
    plan skip_all => "Faulty libpng $libpng_version does not handle hIST";
}

my @tests = (
{
    file => 'ch1n3p04',
    nhist => 15,
},
{
    file => 'ch2n3p08',
    nhist => 256,
},
);

for my $test (@tests) {
    my $file = "$Bin/libpng/$test->{file}.png";
    my $png = read_png_file ($file);
    my $valid = get_valid ($png);
    ok ($valid->{hIST}, "Valid hist in $test->{file}");
    my $hist = $png->get_hIST ();
    is (@$hist, $test->{nhist}, "Right histogram size in $test->{file}");
    my $wpng = copy_png ($png);
    my $rpng = round_trip ($wpng, "$Bin/hist.png");
    is_deeply ($rpng->get_hIST (), $hist, "Round trip of hIST chunk");
}

done_testing ();
exit;
