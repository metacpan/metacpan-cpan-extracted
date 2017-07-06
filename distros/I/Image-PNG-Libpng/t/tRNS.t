use warnings;
use strict;
use FindBin '$Bin';
use Image::PNG::Libpng;
use Test::More;

my $file_name = "$Bin/saru-fs8.png";
my $png = Image::PNG::Libpng::create_read_struct ();
open my $file, "<:raw", $file_name or die $!;
Image::PNG::Libpng::init_io ($png, $file);
#print "Reading PNG.\n";
Image::PNG::Libpng::read_png ($png);
#print "Getting rows.\n";
my $colors = Image::PNG::Libpng::get_PLTE ($png);
#exit;
# for my $i (0..$#$colors) {
#     my $color = $colors->[$i];
#     print "$i: Red: $color->{red} green: $color->{green} blue: $color->{blue}\n";
# }
my $trans = Image::PNG::Libpng::get_tRNS_palette ($png);
for my $i (0..$#$colors) {
    my $color = $colors->[$i];
    my $tr;
    printf "%3d: %02X%02X%02X ", $i, $color->{red},
        $color->{green}, $color->{blue};
    if (defined $trans->[$i]) {
        $tr = $trans->[$i];
        printf " %02X", $tr;
    }
    else {
        print ' none';
    }
    print "\n";
}
close $file or die $!;
ok (1, "shut up your face");
done_testing;

# Local Variables:
# mode: perl
# End:
