#!/usr/bin/env perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lingua-ES-Numbers.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use utf8;

use Test::More tests => 499;

use FindBin;
use lib "$FindBin::Bin/";

BEGIN {
    use_ok('Lingua::SPA::Numeros');
}

#########################

use CardinalsTest;

#my $cardinal = CardinalsTest->init;

my %t_fraccion;

{
    my $num = "1";
    for my $f (qw/ décim centésim milésim diezmilésim cienmilésim /) {
        $t_fraccion{$num} = "un " . $f;
        $num = "0" . $num;
    }
    for my $ll ( CardinalsTest::llones() ) {
        $t_fraccion{$num} = "un " . $ll . "illonésim";
        $num = "0" . $num;
        for my $f (qw/ diez cien mil diezmil cienmil /) {
            $t_fraccion{$num} = "un " . $f . $ll . "illonésim";
            $num = "0" . $num;
        }
    }
}

sub t_fraccion {
    my $genre = "";
    while ( my ( $k, $v ) = each %t_fraccion ) {
        my $t = join( " ", Lingua::SPA::Numeros::fraccion_simple( $k, 0, 1, $genre ) );
        is( $t, $v, "t_fraccion_simple" );
        $t = join( " ", Lingua::SPA::Numeros::fraccion_simple( $k, 0, 0, $genre ) );
        is( $t, $v, "t_fraccion_simple" );
    }
    for ( my $i = 0; $i < 125; $i++ ) {
        my $k = ( 0 x $i ) . 1;
        my $t = join( " ", Lingua::SPA::Numeros::fraccion_simple( 1, -$i, 0, $genre ) );
        my $v = join( " ", Lingua::SPA::Numeros::fraccion_simple( $k, 0, 0, $genre ) );
        is( $t, $v, "t_fraccion_exp" );
        if ( length $k > 8 ) {
            $t = join( " ",
                Lingua::SPA::Numeros::fraccion_simple( "00000001", -$i + 7, 0, $genre ) );
            $v = join( " ",
                Lingua::SPA::Numeros::fraccion_simple( substr( $k, 7 ), -7, 0, $genre ) );
            is( $t, $v, "t_fraccion_exp2" );
        }
    }
    for my $i ( 125, 126 ) {
        my $k = ( 0 x $i ) . 1;
        eval { Lingua::SPA::Numeros::fraccion_simple( 1, -$i, 0, $genre ) };
        ok( $@ =~ /^Fuera de rango/, "t_fraccion_range" );
        eval { Lingua::SPA::Numeros::fraccion_simple( $k, 0, 0, $genre ) };
        ok( $@ =~ /^Fuera de rango/, "t_fraccion_range" );
        eval { Lingua::SPA::Numeros::fraccion_simple( substr( $k, 7 ), -7, 0, $genre ) };
        ok( $@ =~ /^Fuera de rango/, "t_fraccion_range" );
    }
}

t_fraccion;

