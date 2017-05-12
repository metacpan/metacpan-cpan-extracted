use strict;
use warnings;
use Test::More;
use Digest::MurmurHash3::PurePerl;

my $short = 'Hello';
my $long  = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz 0123456789';

subtest 'murmur32' => sub {
    subtest '32bit - short string without seed' => sub {
        my $m32 = murmur32($short);
        is $m32, 0x12da77c8;
    };

    subtest '32bit - short string with seed' => sub {
        my $m32 = murmur32( $short, 42 );
        is $m32, 0x576cae93;
    };

    subtest '32bit - long string without seed' => sub {
        my $m32 = murmur32($long);
        is $m32, 0x3db18f2;
    };

    subtest '32bit - long string with seed' => sub {
        my $m32 = murmur32( $long, 42 );
        is $m32, 0x8ffc6026;
    };
};

subtest 'murmur128' => sub {
    subtest '128bit - short string without seed' => sub {
        my @m128 = murmur128($short);
        is_deeply \@m128, [ 0x2360ae46, 0x5e6336c6, 0xad45b3f4, 0xad45b3f4 ];
    };

    subtest '128bit - short string with seed' => sub {
        my @m128 = murmur128( $short, 42 );
        is_deeply \@m128, [ 0x361babc4, 0xc4a7fd78, 0xd418c3e8, 0xd418c3e8 ];
    };

    subtest '128bit - long string without seed' => sub {
        my @m128 = murmur128($long);
        is_deeply \@m128, [ 0xd31673ff, 0x4ebb82ca, 0xcdc3e38b, 0x6e91e09d ];
    };

    subtest '128bit - long string with seed' => sub {
        my @m128 = murmur128( $long, 42 );
        is_deeply \@m128, [ 0x4c5bb540, 0x2fb5c4f3, 0xc29217ac, 0xc6cfe3af ];
    };

    subtest 'string with longest tail' => sub {
        my $data = '0123456789ABCDE';
        my @m128 = murmur128($data);
        is_deeply \@m128, [ 0x73e53fb8, 0xb2bcf893, 0x7f2e517a, 0xdf83ee55 ];
    };

};

done_testing;
1;
