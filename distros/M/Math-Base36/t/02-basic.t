use Test::More tests => 35;

use strict;
use warnings;

use_ok( 'Math::Base36', qw( :all ) );

use Math::BigInt;

{
    my $num = '3297';
    my $b36 = '2JL';
    my $pad = "0000$b36";

    is( encode_base36( $num ),                  $b36, 'encode' );
    is( decode_base36( $b36 ),                  $num, 'decode' );
    is( decode_base36( encode_base36( $num ) ), $num, 'eat our own dogfood' );
    is( decode_base36( $pad ), $num, 'decode padded number' );
    is( encode_base36( $num, 7 ), $pad, 'encode with padding' );
}

{
    is( decode_base36( 0 ), 0, 'decode( 0 )' );
    is( encode_base36( 0 ), 0, 'encode( 0 )' );
    is( encode_base36( 0, 4 ), '0000', 'encode( 0 ) with padding' );

    is( encode_base36( '000', 2 ),
        '00', 'encode three 3 zeros with 2 padding' );

    # basic digits
    for ( 1 .. 9 ) {
        is( decode_base36( $_ ), $_, "decode( $_ )" );
        is( encode_base36( $_ ), $_, "encode( $_ )" );
    }
}

{
    my $num = Math::BigInt->new( '808281277464764060643139600456536293375' );
    my $b36 = 'ZZZZZZZZZZZZZZZZZZZZZZZZZ';

    is( decode_base36( $b36 ), $num, 'decode large number' );
    is( encode_base36( $num ), $b36, 'encode large number' );
}

{
    my $num = '808281277464764060643139600456536293375';
    my $b36 = 'ZZZZZZZZZZZZZZZZZZZZZZZZZ';

    is( decode_base36( $b36 ), $num, 'decode large number (implicit bigint)' );
    is( encode_base36( $num ), $b36, 'encode large number (implicit bigint)' );
}

{
    eval { decode_base36( '(INVALID)' ); };
    ok( $@, 'invalid base36 numbers in decode throw errors' );

    eval { encode_base36( '(INVALID)' ); };
    ok( $@, 'invalid base10 numbers in encode throw errors' );

    eval { encode_base36( 1, '(INVALID)' ); };
    ok( $@, 'invalid padding in encode throw errors' );
}
