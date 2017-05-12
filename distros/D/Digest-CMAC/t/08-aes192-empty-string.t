use Test::More tests => 2;
use Digest::CMAC;
use Digest::OMAC2;

my $cmac = Digest::CMAC->new(pack 'H*', '8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b');


$cmac->add('');
is($cmac->hexdigest, 'd17ddf46adaacde531cac483de7a9367');



my $omac2 = Digest::OMAC2->new(pack 'H*', '8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b');


$omac2->add('');
is($omac2->hexdigest, '149f579df2129d45a69266898f55aeb2');
