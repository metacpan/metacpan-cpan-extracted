# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lingua-ES-Numbers.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use utf8;

#use lib '/home/opr/W/Projects/Numeros/Lingua-ES-Numbers/lib/';
use Test::More tests => 21835;
BEGIN { use_ok('Lingua::ES::Numeros') }

#########################

require "t/CardinalsTest.pm";

my $cardinal = CardinalsTest->init;

cardinal_test_all($cardinal);

sub cardinal_iterate_all {
    my $self = shift;

    while ( my ( $k, $v ) = each %$self ) {
        if ( $k =~ /^z/ ) {
            my $t = join( " ", Lingua::ES::Numeros::cardinal_simple( substr( $k, 1 ), 0, 0 ) );
            is( $t, $v, "t_cardinal_2" );
        }
        else {
            my $t = join( " ", Lingua::ES::Numeros::cardinal_simple( $k, 0, 1 ) );
            is( $t, $v, "t_cardinal_2" );
        }
    }
}

sub cardinal_iterate_exp {
    my $self = shift;

    for ( my $i = 0; $i < 126; $i++ ) {
        my $k = 1 . ( 0 x $i );
        my $t = join( " ", Lingua::ES::Numeros::cardinal_simple( 1, $i, 0 ) );
        my $v = join( " ", Lingua::ES::Numeros::cardinal_simple( $k, 0, 0 ) );
        is( $t, $v, "t_cardinal_2" );
        if ( $k % 6 == 3 ) {
            $v = $self->get("z$k");
            is( $t, $v, "t_cardinal_2" );
        }
        $t = join( " ", Lingua::ES::Numeros::cardinal_simple( 1, $i, 1 ) );
        $v = join( " ", Lingua::ES::Numeros::cardinal_simple( $k, 0, 1 ) );
        is( $t, $v, "t_cardinal_2" );
        $v = $self->get($k);
        is( $t, $v, "t_cardinal_2" );
    }
}

sub cardinal_iterate_obj {
    my $self = shift;

    my $obj = Lingua::ES::Numeros->new( GENERO => 'a' );
    for my $i ( 0 .. 99 ) {
        my $n = sprintf("%02d", $i);
        $t = $obj->real("11.$n");
        is( $t, "once con $n ctms.", "t_real_2" );
    }
    while ( my ( $k, $v ) = each %$self ) {
        next if $k =~ /^z/;
        my $t = $obj->cardinal($k);
        $v =~ s/un$/una/g;
        if ( $v =~ s/(.*(?:illones|llón))?(.+)// ) {
            my ($hi, $lo) = ($1 || '', $2);
            $lo =~ s/cientos/cientas/g;
            $v = $hi . $lo;
        }
        $v = 'cero' if $v eq '';
        is( $t, $v, "t_cardinal_2" );
    }
}

sub xml_uc($) {
    my $t = uc shift;
    $t =~ s/ACUTE;/acute;/g;
    return $t;
}

sub cardinal_test_real {
    my $self = shift;

    my $obj = Lingua::ES::Numeros->new( SEXO => 'a' );
    $obj->{'FORMATO'} = "CON %s";
    my $t = $obj->real("124.345");
    is( $t, "ciento veinticuatro CON trescientas cuarenta y cinco milésimas", "t_real_2" );
    $obj->{'MAYUSCULAS'} = 1;
    $t = $obj->real("122.345");
    is( $t, uc "ciento veintidós CON trescientas cuarenta y cinco milésimas", "t_real_2" );
    $obj->{'HTML'}    = 1;
    $obj->{'DECIMAL'} = ",";
    $t                = $obj->real("122,345");
    is( $t, xml_uc "ciento veintid&oacute;s CON trescientas cuarenta y cinco mil&eacute;simas",
        "t_real_2" );
    $obj->{'MAYUSCULAS'} = 0;
    $t = $obj->real("122,345");
    is( $t, "ciento veintid&oacute;s CON trescientas cuarenta y cinco mil&eacute;simas",
        "t_real_2" );
    eval { $t = $obj->real("122.345") };
    ok( $@ =~ /^Error de sintaxis/, "Real error de sintaxis" );
    $obj->{'DECIMAL'}    = ".";
    $obj->{'HTML'}       = 0;
    $obj->{'MAYUSCULAS'} = 1;
    $obj->{'ACENTOS'}    = 0;
    $obj->{'POSITIVO'}   = "positivo";
    $t                   = $obj->real("124.345");
    is( $t, uc "positivo ciento veinticuatro CON trescientas cuarenta y cinco milesimas",
        "t_real_2" );
    $obj->{'MAYUSCULAS'} = 0;
    $t = $obj->real("-0.124345e3");
    is( $t, "menos ciento veinticuatro CON trescientas cuarenta y cinco milesimas", "t_real_2" );
    $t = $obj->real("-124345e-3");
    is( $t, "menos ciento veinticuatro CON trescientas cuarenta y cinco milesimas", "t_real_2" );
    $t = $obj->real("-0.224345e3");
    is( $t, "menos doscientas veinticuatro CON trescientas cuarenta y cinco milesimas", "t_real_2" );
    $t = $obj->real("-224345e-3");
    is( $t, "menos doscientas veinticuatro CON trescientas cuarenta y cinco milesimas", "t_real_2" );


    $obj = Lingua::ES::Numeros->new( GENERO => 'o' );
    $obj->{'FORMATO'} = "CON %s";
    $t = $obj->real("124.345");
    is( $t, "ciento veinticuatro CON trescientos cuarenta y cinco milésimos", "t_real_2" );
    $obj->{'MAYUSCULAS'} = 1;
    $t = $obj->real("122.345");
    is( $t, xml_uc "ciento veintidós CON trescientos cuarenta y cinco milésimos", "t_real_2" );
    $obj->{'HTML'}    = 1;
    $obj->{'DECIMAL'} = ",";
    $t                = $obj->real("122,345");
    is( $t, xml_uc "ciento veintid&oacute;s CON trescientos cuarenta y cinco mil&eacute;simos",
        "t_real_2" );
    $obj->{'MAYUSCULAS'} = 0;
    $t = $obj->real("122,345");
    is( $t, "ciento veintid&oacute;s CON trescientos cuarenta y cinco mil&eacute;simos",
        "t_real_2" );
    eval { $t = $obj->real("122.345") };
    ok( $@ =~ /^Error de sintaxis/, "Real error de sintaxis" );
    $obj->{'DECIMAL'}    = ".";
    $obj->{'HTML'}       = 0;
    $obj->{'MAYUSCULAS'} = 1;
    $obj->{'ACENTOS'}    = 0;
    $obj->{'POSITIVO'}   = "positivo";
    $t                   = $obj->real("124.345");
    is( $t, uc "positivo ciento veinticuatro CON trescientos cuarenta y cinco milesimos",
        "t_real_2" );
    $obj->{'MAYUSCULAS'} = 0;
    $t = $obj->real("-0.124345e3");
    is( $t, "menos ciento veinticuatro CON trescientos cuarenta y cinco milesimos", "t_real_2" );
    $t = $obj->real("-124345e-3");
    is( $t, "menos ciento veinticuatro CON trescientos cuarenta y cinco milesimos", "t_real_2" );
    $t = $obj->real("-0.224345e3");
    is( $t, "menos doscientos veinticuatro CON trescientos cuarenta y cinco milesimos", "t_real_2" );
    $t = $obj->real("-224345e-3");
    is( $t, "menos doscientos veinticuatro CON trescientos cuarenta y cinco milesimos", "t_real_2" );

    $obj = $obj->new( GENERO => 'o' );
    $obj->{'FORMATO'} = "CON %2d";
    $t = $obj->real("-0.124345e3");
    is( $t, "menos ciento veinticuatro CON 34", "t_real_2" );
    $t = $obj->real("-124345e-3");
    is( $t, "menos ciento veinticuatro CON 34", "t_real_2" );
    $obj->{'FORMATO'} = "";
    $t = $obj->real("-124345e-3");
    is( $t, "menos ciento veinticuatro", "t_real_2" );
}

sub cardinal_test_all {
    my $self = shift;

    cardinal_iterate_all $self;
    cardinal_iterate_exp $self;
    cardinal_iterate_obj $self;
    cardinal_test_real $self;
}

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
        my $t = join( " ", Lingua::ES::Numeros::fraccion_simple( $k, 0, 1, $genre ) );
        is( $t, $v, "t_fraccion_2" );
        $t = join( " ", Lingua::ES::Numeros::fraccion_simple( $k, 0, 0, $genre ) );
        is( $t, $v, "t_fraccion_2" );
    }
    for ( my $i = 0; $i < 125; $i++ ) {
        my $k = ( 0 x $i ) . 1;
        my $t = join( " ", Lingua::ES::Numeros::fraccion_simple( 1, -$i, 0, $genre ) );
        my $v = join( " ", Lingua::ES::Numeros::fraccion_simple( $k, 0, 0, $genre ) );
        is( $t, $v, "t_fraccion_2" );
    }
}

t_fraccion;

