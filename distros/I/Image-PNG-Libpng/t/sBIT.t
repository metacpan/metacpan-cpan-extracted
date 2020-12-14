use warnings;
use strict;
use Test::More;
use FindBin '$Bin';
use Image::PNG::Libpng ':all';
use Image::PNG::Const ':all';

BEGIN: {
    use lib "$Bin";
    use IPNGLT;
};

my $file = 's38i3p04';
my $ffile = "$Bin/libpng/$file.png";
my $png = read_png_file ($ffile);
ok ($png, "Read $file");
my $sbit = $png->get_sBIT ();
ok ($sbit, "Got an sbit");
is ($sbit->{red}, 4, "Got correct red from example");
is ($sbit->{blue}, 4, "Got correct blue from example");
is ($sbit->{green}, 4, "Got correct green from example");

my %expect = (red => 7, green => 1, blue => 3, alpha => 5);
my $wpng = fake_wpng ({color_type => PNG_COLOR_TYPE_RGBA});
$wpng->set_sBIT (\%expect);
my $rpng = round_trip ($wpng, "$Bin/sBIT.png"); 
is_deeply ($rpng->get_sBIT (), \%expect, "Round trip of sBIT with RGBA PNG");
done_testing ();
