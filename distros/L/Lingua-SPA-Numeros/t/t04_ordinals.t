#!/usr/bin/env perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lingua-ES-Numbers.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use utf8;

use Test::More tests => 31716;
use FindBin;
use lib "$FindBin::Bin";

BEGIN {
    use_ok('Lingua::SPA::Numeros');
}

#########################

use CardinalsTest;

my $cardinal = CardinalsTest->init;

require "OrdinalsTest.pm";

my $ordinal = OrdinalsTest->init($cardinal);

ordinal_test_all($ordinal);

sub ordinal_iterate_all {
    my $self = shift;

    while ( my ( $k, $v ) = each %$self ) {
        my $t = join( " ", Lingua::SPA::Numeros::ordinal_simple( $k, 0, '_' ) );

        #$DB::single = 1 if $t ne $v;
        #$t = join(" ", Lingua::SPA::Numeros::ordinal_simple($k, 0, '_'));
        is( $t, $v, "t_ordinal_2" );
    }
}

sub ordinal_iterate_exp {
    my $self = shift;

    for ( my $i = 0; $i < 126; $i++ ) {
        my $k = 1 . ( 0 x $i );
        my $t = join( " ", Lingua::SPA::Numeros::ordinal_simple( 1, $i, '_' ) );
        my $v = join( " ", Lingua::SPA::Numeros::ordinal_simple( $k, 0, '_' ) );
        is( $t, $v, "t_ordinal_2" );
        if ( $k % 6 == 3 ) {
            $v = $self->get("z$k");
            is( $t, $v, "t_ordinal_2" );
        }
        $t = join( " ", Lingua::SPA::Numeros::ordinal_simple( 1, $i, '_' ) );
        $v = join( " ", Lingua::SPA::Numeros::ordinal_simple( $k, 0, '_' ) );
        is( $t, $v, "t_ordinal_2" );
        $v = $self->get( $k, 0, "_" );
        is( $t, $v, "t_ordinal_2" );
    }
}

sub ordinal_iterate_obj {
    my $self = shift;

    my $obj = Lingua::SPA::Numeros->new( GENERO => 'a' );

    while ( my ( $k, $v ) = each %$self ) {
        next if $k =~ /^0*$/;    # don't take ordinal of 0
        my $t = $obj->ordinal($k);
        isnt( $t, $v, "t_ordinal_2" );
        $v =~ s/_/a/g;
        is( $t, $v, "t_ordinal_2" );
    }

    eval { $obj->ordinal( 1 x 126 ) };
    ok( !$@, "Ordinal en rango" );

    eval { $obj->ordinal( 1 x 127 ) };
    ok( $@ =~ /^Fuera de rango/, "Ordinal fuera de rango" );

    eval { $obj->ordinal(-1) };
    ok( $@ =~ /^Ordinal negativo/, "Ordinal negativo" );

    ok( $obj->ordinal(1)      eq "primera", "Ordinal 1a" );
}

sub ordinal_test_all {
    my $self = shift;

    ordinal_iterate_all $self;
    ordinal_iterate_exp $self;
    ordinal_iterate_obj $self;
}

