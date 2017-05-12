#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;

use JSON::Meth;
use JSON::MaybeXS;

eval '[42]->$json';
like $@, qr/requires explicit/, '$json is not exported by default';

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
};

{
    my $json_str = $data->$j;

    cmp_deeply(
      decode_json($json_str),
      $data,
      'postfix: sane result on encode',
    );

    cmp_deeply(
        $json_str->$j,
        $data,
        'postfix: sane result on decode',
    );
}

{
    my $json_str = { %$data }->$j;

    cmp_deeply(
      decode_json($json_str),
      $data,
      'postfix raw: sane result on encode',
    );

    cmp_deeply(
        $json_str->$j,
        $data,
        'postfix raw: sane result on decode',
    );
}

{
    cmp_deeply(
        '["look","ma!","no","vars"]'->$j,
        [ qw/look ma! no vars/ ],
        'postfix raw string: sane result on decode',
    );
}

{
    my $json_str = $j->( $data );

    cmp_deeply(
      decode_json( $json_str ),
      $data,
      'prefix: sane result on encode',
    );

    cmp_deeply(
        $j->( $json_str ),
        $data,
        'prefix: sane result on decode',
    );
}

done_testing();

__END__