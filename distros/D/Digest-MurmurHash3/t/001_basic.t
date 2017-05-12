use strict;
use Test::More;
use Config;
use constant HAVE_64BITINT => $Config{use64bitint};

BEGIN {
    use_ok "Digest::MurmurHash3", "murmur32", "murmur128_x86", "murmur128_x64";
}

no warnings 'portable'; # silence 64bit+ integer warnings

my @data = (
    [ "Hello",  0x12da77c8,
        [ 0x2360ae46, 0x5e6336c6, 0xad45b3f4, 0xad45b3f4 ],
        [ HAVE_64BITINT ?
            ( 0x35b974ff55d4c41c, 0xa000eacf29125544 ) :
            ()
        ],
    ],
    [ "Hello1", 0x6357e0a6,
        [ 0x8eb0cf41, 0x641b2401, 0xbc4c0dfc, 0xbc4c0dfc ],
        [ HAVE_64BITINT ?
            ( 0xafaafd85a8c00a56, 0xdc0dbef0c7059c1e ) :
            ()
        ]
    ],
    [ "Hello2", 0xe5ce223e,
        [ 0xd3bcfc45, 0x66782162, 0x4beab2d1, 0x4beab2d1 ],
        [ HAVE_64BITINT ?
            ( 0x749556211f5f36ec, 0xfec442066e8ecb20 ) :
            () 
        ]
    ],
);


foreach my $data ( @data ) {
    { # 32 bit
        my $value = murmur32( $data->[0] );
        is $value, $data->[1],
            "Hash (32 bit) for input for '$data->[0]' was $data->[1] ($value)"
    }

    { # 128 bit
        my ($v1, $v2, $v3, $v4) = murmur128_x86( $data->[0] );
        is_deeply
            [ $v1, $v2, $v3, $v4 ],
            $data->[2],
            sprintf "Hash (128bit x86) for input for '%s' was %s (%s)",
                $data->[0],
                explain( [$v1, $v2, $v3, $v4] ),
                explain( $data->[2] ),
        ;
    }

    SKIP: {
        skip 1, "This test requires 64bit int" unless HAVE_64BITINT;

        my ($v1, $v2) = murmur128_x64( $data->[0] );
        is_deeply
            [ $v1, $v2 ],
            $data->[3],
            sprintf "Hash (128bit x64) for input for '%s' was %s (%s)",
                $data->[0],
                explain( [$v1, $v2] ),
                explain( $data->[3] ),
        ;
    }
}

done_testing;