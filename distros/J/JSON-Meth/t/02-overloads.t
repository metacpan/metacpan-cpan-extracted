#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;

use JSON::Meth;
use JSON::MaybeXS;

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

eval { $j->$j };
like $@, qr/You tried to call \$j->\$j/, 'we give a proper error';

is( $data->$j, "$j", 'encode stringification works', );
cmp_deeply(
    "$j"->$j->{mer},
    $data->{mer},
    'stringify, then decode, and hash-deref',
);

cmp_deeply(
    $j->{mer}->$j,
    "$j",
    'traverse data then encode again and interpolate',
);

cmp_deeply(
    $j->$j,
    [@$j],
    'decode stored data and compare with array-deref',
);

cmp_deeply(
    $data->$j->$j->{foor}->$j->$j,
    {%$j},
    'decode stored data and compare with hash-deref',
);

cmp_deeply(
    { boor => [ 42 ] },
    {%$j},
    'compare hash-deref to something known',
);


cmp_deeply(
    $data->$j->$j->$j->$j->$j->$j->$j->$j->$j->$j->$j->$j,
    $data,
    '$j->$j->$j overload!',
);

cmp_deeply(
    decode_json($data->$j->$j->$j->$j->$j->$j->$j->$j->$j->$j->$j->$j->$j),
    $data,
    '$j->$j->$j overload with encoded result!',
);


done_testing();

__END__