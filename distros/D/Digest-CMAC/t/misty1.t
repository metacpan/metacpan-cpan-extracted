use Test::More tests => 6;
use Digest::CMAC;
use strict;

SKIP: {
    my $key = pack 'H*', '2b7e151628aed2a6abf7158809cf4f3c';
    my $cmac;
    eval { $cmac = Digest::CMAC->new($key, 'Crypt::Misty1') };
    skip "Crypt::Misty1 not installed", 6 if $@;

    is(unpack("H*", $cmac->{Lu}),  'd292af0d3151fc70');
    is(unpack("H*", $cmac->{Lu2}), 'a5255e1a62a3f8fb');

    # empty string
    $cmac->add('');
    is($cmac->hexdigest, '9e8c23bbd1b826c1');

    # 8byte
    $cmac->add(pack 'H*', '6bc1bee22e409f96');
    is($cmac->hexdigest, '551f9a543ef664ba');
    # 16byte
    $cmac->add(pack 'H*', '6bc1bee22e409f96e93d7e117393172a');
    is($cmac->hexdigest, 'd8e8e3c93e6ccb74');
    # 40byte
    $cmac->add(pack 'H*',
        '6bc1bee22e409f96e93d7e117393172a'.
        'ae2d8a571e03ac9c9eb76fac45af8e51'.
        '30c81c46a35ce411'
    );
    is($cmac->hexdigest, '449d4f17c00e1974');
}
