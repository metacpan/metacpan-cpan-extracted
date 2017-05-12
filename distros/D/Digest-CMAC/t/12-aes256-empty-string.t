use Test::More tests => 2;
use Digest::CMAC;
use Digest::OMAC2;

my $cmac = Digest::CMAC->new(pack 'H*', '603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4');
$cmac->add('');
is($cmac->hexdigest, '028962f61b7bf89efc6b551f4667d983');


my $omac2 = Digest::OMAC2->new(pack 'H*', '603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4');
$omac2->add('');
is($omac2->hexdigest, '47fbde71866eae6080355b5fc7ff704c');
