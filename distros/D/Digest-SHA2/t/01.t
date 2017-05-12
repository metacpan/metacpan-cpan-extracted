use diagnostics;
use strict;
use warnings;
use Test::More tests => 4;
BEGIN {
    use_ok('Digest::SHA2')
};

BEGIN {
    my $sha2obj = new Digest::SHA2;
    $sha2obj->add("abc");
    my $digest = $sha2obj->hexdigest();
    is("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
        $digest);

    my $sha2obj2 = new Digest::SHA2 384;
    $sha2obj2->add("abc");
    my $digest2 = $sha2obj2->hexdigest();
    is("cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7", $digest2);

    my $sha2obj3 = new Digest::SHA2 512;
    $sha2obj3->add("abc");
    my $digest3 = $sha2obj3->hexdigest();
    is("ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f", $digest3);
};

