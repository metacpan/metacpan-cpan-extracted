use warnings;
use strict;
use Test::More;
use Image::PNG::Libpng ':all';
use FindBin '$Bin';

BEGIN: {
    use lib "$Bin";
    use IPNGLT;
};

chunk_ok ('cHRM_XYZ');

my $wpng = fake_wpng ();

# Use fixed values here since random values sometimes don't work.

# my %chrm;
# use Data::Dumper;
# for my $color (qw!red blue green!) {
#     for my $dim (qw!x z!) {
# 	$chrm{"${color}_$dim"} = rand ();
#     }
#     # The y values need to sum to 1.
#     $chrm{"${color}_y"} = 1/3.0;
# }
# print Dumper (\%chrm);
my %chrm = (
    'blue_x' => '0.783478577193943',
    'green_x' => '0.57222996059598',
    'red_z' => '0.479404662360565',
    'green_y' => '0.333333333333333',
    'blue_z' => '0.973139769254836',
    'green_z' => '0.85632538956996',
    'blue_y' => '0.333333333333333',
    'red_x' => '0.809770379521982',
    'red_y' => '0.333333333333333'
);

$wpng->set_cHRM_XYZ (\%chrm);
my $rpng = round_trip ($wpng, "$Bin/chrm-xyz.png");
my $valid = $rpng->get_valid ();
ok ($valid->{'cHRM'}, "got a cHRM chunk");
my $rt = $rpng->get_cHRM_XYZ ();
my $eps = 0.01;
for my $k (keys %chrm) {
    cmp_ok (abs ($rt->{$k} - $chrm{$k}), '<', $eps,
	    "round trip of $k ($rt->{$k}, $chrm{$k}) of cHRM_XYZ");
}
done_testing ();
