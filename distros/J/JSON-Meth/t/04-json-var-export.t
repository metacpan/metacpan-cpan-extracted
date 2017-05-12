#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;

use JSON::Meth '$json';
use JSON::MaybeXS;

eval '[42]->$j';
like $@, qr/requires explicit/, '$j is not exported';

my $data = {
    foo => 'bar',
    baz => 'ber',
    mer => [
        meer => 1,
        moor => {
            meh => 'hah',
            hih => [
                'hoh',
                undef,
                0,
            ]
        },
    ],
    foor => {
        boor => [
            '42',
        ],
    },
};

cmp_deeply(
    decode_json( $data->$json ),
    $data,
    q{$json works},
);

done_testing();

__END__