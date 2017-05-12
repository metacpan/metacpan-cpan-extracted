use Test::More tests => 4;
use Digest::CMAC;
use Digest::OMAC2;

my $cmac = Digest::CMAC->new(pack 'H*', '8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b');
is(unpack("H*", $cmac->{Lu}),  '448a5b1c93514b273ee6439dd4daa296');
is(unpack("H*", $cmac->{Lu2}), '8914b63926a2964e7dcc873ba9b5452c');


my $omac2 = Digest::OMAC2->new(pack 'H*', '8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b');
is(unpack("H*", $omac2->{Lu}),  '448a5b1c93514b273ee6439dd4daa296');
is(unpack("H*", $omac2->{Lu2}), '912296c724d452c9cfb990e77536a8e6');

