use diagnostics;
use strict;
use warnings;
use Test::More tests => 4;
BEGIN {
    use_ok('Digest::SHA2')
};

BEGIN {
    my $sha2obj = new Digest::SHA2;
    $sha2obj->add("");
    my $digest = $sha2obj->hexdigest();
    is("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        $digest);

    my $sha2obj2 = new Digest::SHA2 384;
    $sha2obj2->add("");
    my $digest2 = $sha2obj2->hexdigest();
    is("38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b", $digest2);

    my $sha2obj3 = new Digest::SHA2 512;
    $sha2obj3->add("");
    my $digest3 = $sha2obj3->hexdigest();
    is("cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e", $digest3);
};

