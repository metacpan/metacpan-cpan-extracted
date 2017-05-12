use Test::More tests => 4;
use Digest::CMAC;
use Digest::OMAC2;

my $cmac = Digest::CMAC->new(pack 'H*', '2b7e151628aed2a6abf7158809cf4f3c');

is(unpack("H*", $cmac->{Lu} ),  'fbeed618357133667c85e08f7236a8de');
is(unpack("H*", $cmac->{Lu2} ), 'f7ddac306ae266ccf90bc11ee46d513b');


my $omac2 = Digest::OMAC2->new(pack 'H*', '2b7e151628aed2a6abf7158809cf4f3c');

is(unpack("H*", $omac2->{Lu} ),  'fbeed618357133667c85e08f7236a8de');
is(unpack("H*", $omac2->{Lu2} ), 'befbb5860d5c4cd99f217823dc8daa74');
