#! perl -slw
use strict; use Config;
use Inline C => Config => BUILD_NOISY => 1;
use Inline C => <<'END_C',  NAME => 'diffBench', CLEAN_AFTER_BUILD =>0;

SV *diffAoA( U32 n ) {
    AV *av = newAV();
    U32 i;

    for( i = 0; i < n/2; ++i ) {
        AV *av2 = newAV();
        av_push( av2, newSViv( i*2   ) );
        av_push( av2, newSViv( i*2+1 ) );
        av_push( av, (SV*)av2 );
    }
    return newRV_noinc( (SV*)av );
}

SV *diffPacked( U32 n ) {
    U32 *diffs = malloc( sizeof( U32 ) * n );
    SV *packed;
    U32 i;

    for( i = 0; i < n; ++i ) {
        diffs[ i ] = i;
    }
    packed = newSVpv( (char *)diffs, sizeof( U32 ) * n );
    free( diffs );
    return packed;
}

void diffPackedList( U32 n ) {
    inline_stack_vars;
    U32 i;

    inline_stack_reset;
    for( i = 0; i < n/2; ++i ) {
        U32 a[ 2 ] = { i*2, i*2+1 };

        inline_stack_push( sv_2mortal( newSVpv( (char*)a, 8 ) ) );
    }
    inline_stack_done;
    inline_stack_return( n/2 );
    return;
}

SV *diff2dString( U32 n ) {
    SV *diffs = newSVpv( "", 0 );
    U32 i;

    for( i = 0; i < n/2; ++i ) {
        sv_catpvf( diffs, "%u:%u ", i*2, i*2+1 );
    }
    return diffs;
}

void diff1dList( U32 n ) {
    inline_stack_vars;
    U32 i;

    inline_stack_reset;
    for( i = 0; i < n/2; ++i ) {
        inline_stack_push( sv_2mortal( newSVpvf( "%u:%u", i*2, i*2+1 )
 ) );
    }
    inline_stack_done;
    inline_stack_return( n/2 );
    return;
}

void diffList( U32 n ) {
    inline_stack_vars;
    U32 i;

    inline_stack_reset;
    for( i = 0; i < n; ++i ) {
        inline_stack_push( sv_2mortal( newSViv( i ) ) );
    }
    inline_stack_done;
    inline_stack_return( n );
    return;
}

void diffLoA( U32 n ) {
    inline_stack_vars;
    U32 i;

    inline_stack_reset;
    for( i = 0; i < n/2; ++i ) {
        AV *av2 = newAV();
        av_push( av2, newSViv( i*2   ) );
        av_push( av2, newSViv( i*2+1 ) );
        inline_stack_push( newRV_noinc( (SV*)av2 ) );
    }
    inline_stack_done;
    inline_stack_return( n/2 );
    return;
}

SV * diffBits( U32 n ) {
    //unsigned __int64 bits = 0;
    IV bits = 0;
    U32 i;

    for( i = 0; i < n/2; ++i ) {
        bits |= ( 1ull << ( i*2) );
        bits |= ~( 1ull << ( i*2+1 ) );
    }
    return newSViv( bits );
}

END_C

use Data::Dump qw[ pp ];
use Benchmark qw[ cmpthese ];

our $N //= 10;

cmpthese -1, {
    AoA => q[
        my $AoA = diffAoA( $N ); # pp $AoA;
        for my $pair ( @{ $AoA } ) {
            my( $x, $y ) = @{ $pair };
        }
    ],
    packed => q[
        my $packed = diffPacked( $N ); # pp $packed;
        while( length( $packed ) ) {
            my( $x, $y ) = unpack 'VV', substr( $packed, 0, 8, '' );
        }
    ],
    packedList => q[
        for my $pair ( diffPackedList( $N ) ) {
            my( $x, $y ) = unpack 'VV', $pair;
        }
    ],
    twoDel => q[
        my $string2d = diff2dString( $N ); # pp $string2d;
        for my $pair ( split ' ', $string2d ) {
            my( $x, $y ) = split ':', $pair;
        }
    ],
    oneDelList => q[
        for my $pair ( diff1dList( $N ) ) {
            my( $x, $y ) = split ':', $pair;
        }
    ],
    list => q[
        my @array = diffList( $N ); # pp \@array;
        while( @array ) {
            my( $x, $y ) = ( shift @array, shift @array );
        }
    ],
    LoA => q[
        my @array = diffLoA( $N ); # pp \@array;
        for my $pair ( @array ) {
            my( $x, $y ) = @{ $pair };
        }
    ],
    bits => q[
        my $bits = diffBits( $N );
        for( my $i =0; $i < 64; ++$i ) {
            my( $x, $y ) = ( ( $bits & ( 1 << ( $i*2 ) ) ) >> ( $i *2 ),
                           ( $bits & ( 1 << ( $i*2+1) ) ) >> ( $i*2+1 ) );
        }
    ],
};

__END__
