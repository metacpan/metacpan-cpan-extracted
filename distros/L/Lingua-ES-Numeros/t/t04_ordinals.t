# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lingua-ES-Numbers.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use utf8;

#use lib '/home/opr/W/Projects/Numeros/Lingua-ES-Numbers/lib/';
use Test::More tests => 31719;
BEGIN { use_ok('Lingua::ES::Numeros') }

#########################

require "t/CardinalsTest.pm";

my $cardinal = CardinalsTest->init;

require "t/OrdinalsTest.pm";

my $ordinal = OrdinalsTest->init($cardinal);

ordinal_test_all($ordinal);

sub ordinal_iterate_all {
    my $self = shift;

    while ( my ( $k, $v ) = each %$self ) {
        my $t = join( " ", Lingua::ES::Numeros::ordinal_simple( $k, 0, '_' ) );

        #$DB::single = 1 if $t ne $v;
        #$t = join(" ", Lingua::ES::Numeros::ordinal_simple($k, 0, '_'));
        is( $t, $v, "t_ordinal_2" );
    }
}

sub ordinal_iterate_exp {
    my $self = shift;

    for ( my $i = 0; $i < 126; $i++ ) {
        my $k = 1 . ( 0 x $i );
        my $t = join( " ", Lingua::ES::Numeros::ordinal_simple( 1, $i, '_' ) );
        my $v = join( " ", Lingua::ES::Numeros::ordinal_simple( $k, 0, '_' ) );
        is( $t, $v, "t_ordinal_2" );
        if ( $k % 6 == 3 ) {
            $v = $self->get("z$k");
            is( $t, $v, "t_ordinal_2" );
        }
        $t = join( " ", Lingua::ES::Numeros::ordinal_simple( 1, $i, '_' ) );
        $v = join( " ", Lingua::ES::Numeros::ordinal_simple( $k, 0, '_' ) );
        is( $t, $v, "t_ordinal_2" );
        $v = $self->get( $k, 0, "_" );
        is( $t, $v, "t_ordinal_2" );
    }
}

sub ordinal_iterate_obj {
    my $self = shift;

    my $obj = Lingua::ES::Numeros->new( GENERO => 'a' );

    while ( my ( $k, $v ) = each %$self ) {
        next if $k =~ /^0*$/;    # don't take ordinal of 0
        my $t = $obj->ordinal($k);
        isnt( $t, $v, "t_ordinal_2" );
        $v =~ s/_/a/g;
        is( $t, $v, "t_ordinal_2" );
    }

    eval { $obj->ordinal( 1 x 126 ) };
    ok( !$@, "Ordinal in range" );

    eval { $obj->ordinal( 1 x 127 ) };
    ok( $@ =~ /^Fuera de rango/, "Ordinal out of range" );

    eval { $obj->ordinal(-1) };
    ok( $@ =~ /^Ordinal negativo/, "Negative ordinal" );

    # FIXME: some way to check carp ?
    eval { $obj->ordinal(-0) };
    ok( !$@, "Ordinal -0" );
    eval { $obj->ordinal(0) };
    ok( !$@, "Ordinal 0" );

    ok( $obj->ordinal(3.1416) eq "tercera", "Ordinal PI" );
    ok( $obj->ordinal(1)      eq "primera", "Ordinal 1a" );
}

sub ordinal_test_all {
    my $self = shift;

    ordinal_iterate_all $self;
    ordinal_iterate_exp $self;
    ordinal_iterate_obj $self;
}

