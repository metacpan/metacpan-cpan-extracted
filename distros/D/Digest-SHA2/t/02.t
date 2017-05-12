use diagnostics;
use strict;
use warnings;
use Test::More tests => 4;
BEGIN {
    use_ok('Digest::SHA2')
};

BEGIN {
    my $sha2obj = new Digest::SHA2;
    $sha2obj->add("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq");
    my $digest = $sha2obj->hexdigest();
    is("248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",
        $digest);

    my $sha2obj2 = new Digest::SHA2 384;
    $sha2obj2->add("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq");
    my $digest2 = $sha2obj2->hexdigest();
    is("3391fdddfc8dc7393707a65b1b4709397cf8b1d162af05abfe8f450de5f36bc6b0455a8520bc4e6f5fe95b1fe3c8452b", $digest2);

    my $sha2obj3 = new Digest::SHA2 512;
    $sha2obj3->add("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq");
    my $digest3 = $sha2obj3->hexdigest();
    is("204a8fc6dda82f0a0ced7beb8e08a41657c16ef468b228a8279be331a703c33596fd15c13b1b07f9aa1d3bea57789ca031ad85c7a71dd70354ec631238ca3445", $digest3);
};

