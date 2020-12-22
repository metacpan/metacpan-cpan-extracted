use warnings;
use strict;
use FindBin '$Bin';
use Test::More;
use Image::PNG::Libpng ':all';
use Image::PNG::Const ':all';

BEGIN: {
    use lib "$Bin";
    use IPNGLT;
};

# Test reading a background.

my $png = create_read_struct ();
open my $fh, "<:raw", "$Bin/libpng/bgyn6a16.png" or die $!;
init_io ($png, $fh);
read_png ($png);
close $fh or die $!;
my $bg = get_bKGD ($png);
ok ($bg, "get background got OK");
my %col = (
    green => 65535,
    index => 0,
    blue => 0,
    gray => 0,
    red => 65535,
);

for my $col (keys %col) {
    is ($bg->{$col}, $col{$col}, "$col background");
}
my $valid = get_valid ($png);
my @expect = qw/IDAT bKGD gAMA/;
for my $k (@expect) {
    ok ($valid->{$k}, "Valid $k");
}

# Test writing a background.

my $bKGD_file = "$Bin/bKGD-test.png";
rmfile ($bKGD_file);
my $wpng = create_write_struct ();
open my $wfh, ">:raw", $bKGD_file or die $!;
init_io ($wpng, $wfh);
my %IHDR = (
    width => 1,
    height => 1,
    color_type => PNG_COLOR_TYPE_RGB_ALPHA,
    bit_depth => 8,
);
set_IHDR ($wpng, \%IHDR);
set_rows ($wpng, ["XXXX"]);
my %bKGD = (green => 21, blue => 34, red => 99);
set_bKGD ($wpng, \%bKGD);
write_png ($wpng);
close $wfh or die $!;

# Test we got the same thing back from it.

my $rpng = create_read_struct ();
open my $rfh, "<:raw", $bKGD_file or die $!;
init_io ($rpng, $rfh);
read_png ($rpng);
close $rfh or die $!;
my $rbg = get_bKGD ($rpng);
for my $k (keys %bKGD) {
    is ($rbg->{$k}, $bKGD{$k}, "Key $k OK in written then read file");
}
rmfile ($bKGD_file);
done_testing ();
exit;
