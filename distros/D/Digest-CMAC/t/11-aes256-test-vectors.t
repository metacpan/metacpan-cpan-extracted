use Test::More tests => 4;
use Digest::CMAC;
use Digest::OMAC2;

my $cmac = Digest::CMAC->new(pack 'H*', '603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4');
is(unpack("H*", $cmac->{Lu} ),  'cad1ed03299eedac2e9a99808621502f');
is(unpack("H*", $cmac->{Lu2} ), '95a3da06533ddb585d3533010c42a0d9');


my $omac2 = Digest::OMAC2->new(pack 'H*', '603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4');
is(unpack("H*", $omac2->{Lu} ),  'cad1ed03299eedac2e9a99808621502f');
is(unpack("H*", $omac2->{Lu2} ), '72b47b40ca67bb6b0ba6a6602188542a');

