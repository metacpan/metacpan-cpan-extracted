package FLAT::Regex::Util;
use parent 'FLAT::Regex';

use FindBin qw/$Bin/;
use lib qq{$Bin/../lib};

use strict;
use Carp;

sub get_symbol {
    my $symbol_len = shift;
    $symbol_len //= 1;
    my @symbols = qw/0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z/;
    my $symbol  = q{};
    for ( 1 .. $symbol_len ) {
        $symbol .= $symbols[ rand(36) ];
    }
    return ( $symbol_len > 1 ) ? sprintf( "[%s]", $symbol ) : $symbol;
}

sub get_op {
    my @ops = ( '*', '+', '&', '', '', '', '', '', '', '' );
    return $ops[ rand(10) ];
}

sub get_random {
    my ( $length, $symbol_len ) = @_;
    my $string = '';
    if ( 1 < $length ) {
        $string = get_symbol() . get_op() . get_random( --$length );
    }
    else {
        $string = get_symbol($symbol_len);
    }
    return $string;
}

sub random_pre {
    my ( $length, $symbol_len ) = @_;
    $length     //= 8;
    $symbol_len //= 1;
    return FLAT::Regex::WithExtraOps->new( get_random( $length, $symbol_len ) );
}

1;
