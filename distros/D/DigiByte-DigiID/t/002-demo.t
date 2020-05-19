use strict;
use warnings;
use Test::More;
use DigiByte::DigiID qw(verify_signature);

eval {
    verify_signature(qw(
        foobar
        foobar123
        digiid://foo.bar
    ))
};

like $@, qr/Invalid checksum/;

ok verify_signature(qw(
    DTwryNZnSTt4yAPDGPJeNRaEd1C32X7tUz
    HwX4ZhkLhFtIGwqKOdTrTgLeLRvJNepmPWyMckDPckHSOTbMu5f9W2VE9gF2Uj3Aeu2UMQMMGbavH2OIcbXqxbk=
    digiid://192.168.0.158:2001/callback?x=3144&u=1
));

done_testing;
