use strict;
use warnings;

use Test::Most;
use lib glob 'modules/*/lib';

use Encode::Base58::BigInt;

subtest base => sub {
    is encode_base58('0'), '1';
    is decode_base58('1'), '0';

    is encode_base58('1'), '2';
    is decode_base58('2'), '1';

    is encode_base58("0xffffff"), '2tZhk';
    is decode_base58('2tZhk'), '16777215';

    is encode_base58("0xffffffff"), '7xwQ9g';
    is decode_base58('7xwQ9g'), '4294967295';

    is encode_base58('9235113611380768826'), 'nrkMyzsS7w7';
    is decode_base58('nrkMyzsS7w7'), '9235113611380768826';

    for my $i (qw/9235113611380768826 9235114153936237539 9235114151314841248 9235114151314993313 9235114142823296511/) {
        is decode_base58(encode_base58($i)), $i, "test $i";
    }

    is decode_base58('ZD'), '3343', "same";
    is decode_base58('ZO'), '3343', "same";
    is decode_base58('Z0'), '3343', "same";

    is decode_base58('Z1'), '3306', "same";
    is decode_base58('Zl'), '3306', "same";
    is decode_base58('ZI'), '3306', "same";
    is decode_base58('motemen'), '776121849679', "same";

    done_testing;
};

subtest dies => sub {
    throws_ok { decode_base58('.'); } qr/Invalid Base58/, "invalid code";
    throws_ok { decode_base58('//'); } qr/Invalid Base58/, "invalid code";

    done_testing;
};

done_testing;
