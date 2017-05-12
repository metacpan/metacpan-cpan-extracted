use Test::More tests => 2;
use Digest::CMAC;
use Digest::OMAC2;

my $cmac = Digest::CMAC->new(pack 'H*', '2b7e151628aed2a6abf7158809cf4f3c');

$cmac->add('');
is(unpack("H*", $cmac->digest), 'bb1d6929e95937287fa37d129b756746');

my $omac2 = Digest::OMAC2->new(pack 'H*', '2b7e151628aed2a6abf7158809cf4f3c');
$omac2->add('');
is(unpack("H*", $omac2->digest), 'f6bc6a41f4f84593809e59b719299cfe');
