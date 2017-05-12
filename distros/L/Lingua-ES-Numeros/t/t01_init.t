# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lingua-ES-Numbers.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use utf8;
use strict;
use warnings;

use Test::More tests => 85;
BEGIN { use_ok('Lingua::ES::Numeros') }

#########################

sub accesors {
    my $obj = Lingua::ES::Numeros->new();

    is( $obj->acentos,     1,                         "accesor acentos" );
    is( $obj->mayusculas,  0,                         "accesor mayusculas" );
    is( $obj->unmil,       1,                         "accesor unmil" );
    is( $obj->html,        0,                         "accesor html" );
    is( $obj->decimal,     '.',                       "accesor decimal" );
    is( $obj->separadores, '_',                       "accesor separadores" );
    is( $obj->genero,      Lingua::ES::Numeros::MALE, "accesor genero" );
    is( $obj->positivo,    '',                        "accesor positivo" );
    is( $obj->negativo,    'menos',                   "accesor negativo" );
    is( $obj->formato,     'con %02d ctms.',          "accesor formato" );

    is( $obj->accents,    $obj->acentos,     "accesor accents" );
    is( $obj->uppercase,  $obj->mayusculas,  "accesor uppercase" );
    is( $obj->separators, $obj->separadores, "accesor separators" );
    is( $obj->gender,     $obj->genero,      "accesor gender" );
    is( $obj->positive,   $obj->positivo,    "accesor positive" );
    is( $obj->negative,   $obj->negativo,    "accesor negative" );
    is( $obj->format,     $obj->formato,     "accesor format" );

    is( $obj->acentos(0),                          $obj, "accesor acentos" );
    is( $obj->mayusculas(1),                       $obj, "accesor mayusculas" );
    is( $obj->unmil(0),                            $obj, "accesor unmil" );
    is( $obj->html(1),                             $obj, "accesor html" );
    is( $obj->decimal(","),                        $obj, "accesor decimal" );
    is( $obj->separadores("*"),                    $obj, "accesor separadores" );
    is( $obj->genero(Lingua::ES::Numeros::FEMALE), $obj, "accesor genero" );
    is( $obj->positivo('mas'),                     $obj, "accesor positivo" );
    is( $obj->negativo('negativo'),                $obj, "accesor negativo" );
    is( $obj->formato('.'),                        $obj, "accesor formato" );

    is( $obj->acentos,     0,                           "accesor acentos" );
    is( $obj->mayusculas,  1,                           "accesor mayusculas" );
    is( $obj->unmil,       0,                           "accesor unmil" );
    is( $obj->html,        1,                           "accesor html" );
    is( $obj->decimal,     ',',                         "accesor decimal" );
    is( $obj->separadores, '*',                         "accesor separadores" );
    is( $obj->genero,      Lingua::ES::Numeros::FEMALE, "accesor genero" );
    is( $obj->positivo,    'mas',                       "accesor positivo" );
    is( $obj->negativo,    'negativo',                  "accesor negativo" );
    is( $obj->formato,     '.',                         "accesor formato" );

    is( $obj->accents,    0,                           "accesor accents" );
    is( $obj->uppercase,  1,                           "accesor uppercase" );
    is( $obj->separators, '*',                         "accesor separators" );
    is( $obj->gender,     Lingua::ES::Numeros::FEMALE, "accesor gender" );
    is( $obj->positive,   'mas',                       "accesor positive" );
    is( $obj->negative,   'negativo',                  "accesor negative" );
    is( $obj->format,     '.',                         "accesor format" );
}

sub parser {
    my $num;
    my ( $s, $i, $f, $e );

    $num = join( "_", split( "", 9 x 9 ) );

    ( $s, $i, $f, $e ) = Lingua::ES::Numeros::parse_num( $num, ".", "_" );
    ok( ( $s == 1 and $i == 999999999 and $f == 0 and $e == 0 ), "parse_num 1" );

    ( $s, $i, $f, $e ) = Lingua::ES::Numeros::parse_num( "-$num", ".", "_" );
    ok( ( $s == -1 and $i == 999999999 and $f == 0 and $e == 0 ), "parse_num 2" );

    ( $s, $i, $f, $e ) = Lingua::ES::Numeros::parse_num( "${num}e-6", ".", "_" );
    ok( ( $s == 1 and $i == 999 and $f == 999999 and $e == 0 ), "parse_num 3" );

    ( $s, $i, $f, $e ) = Lingua::ES::Numeros::parse_num( "${num}e-9", ".", "_" );
    ok( ( $s == 1 and $i == 0 and $f == 999999999 and $e == 0 ), "parse_num 4" );

    ( $s, $i, $f, $e ) = Lingua::ES::Numeros::parse_num( "${num}e-18", ".", "_" );
    ok( ( $s == 1 and $i == 0 and $f == 999999999 and $e == -9 ), "parse_num 5" );

    ( $s, $i, $f, $e ) = Lingua::ES::Numeros::parse_num( "${num}e+6", ".", "_" );
    ok( ( $s == 1 and $i == 999999999 and $f == 0 and $e == 6 ), "parse_num 6" );

    my $n = join( "_", split( "", 9 x 6 ) );
    $n .= "." . $n;
    for my $num ( $n, "+$n", "-$n" ) {
        my $st = $num =~ /^-/ ? -1 : 1;

        ( $s, $i, $f, $e ) = Lingua::ES::Numeros::parse_num( $num, ".", "_" );
        ok( ( $s == $st and $i == 999999 and $f == 999999 and $e == 0 ), "parse_num A" );

        for my $xe (qw/ e0 e+0 e-0 /) {
            ( $s, $i, $f, $e ) = Lingua::ES::Numeros::parse_num( "${num}$xe", ".", "_" );
            ok( ( $s == $st and $i == 999999 and $f == 999999 and $e == 0 ), "parse_num B" );
        }

        ( $s, $i, $f, $e ) = Lingua::ES::Numeros::parse_num( "${num}e-3", ".", "_" );
        ok( ( $s == $st and $i == 999 and $f == 999999999 and $e == 0 ), "parse_num C" );

        ( $s, $i, $f, $e ) = Lingua::ES::Numeros::parse_num( "${num}e-6", ".", "_" );
        ok( ( $s == $st and $i == 0 and $f eq "999999999999" and $e == 0 ), "parse_num D" );

        ( $s, $i, $f, $e ) = Lingua::ES::Numeros::parse_num( "${num}e-9", ".", "_" );
        ok( ( $s == $st and $i == 0 and $f eq "999999999999" and $e == -3 ), "parse_num E" );

        ( $s, $i, $f, $e ) = Lingua::ES::Numeros::parse_num( "${num}e+3", ".", "_" );
        ok( ( $s == $st and $i == 999999999 and $f == 999 and $e == 0 ), "parse_num F" );

        ( $s, $i, $f, $e ) = Lingua::ES::Numeros::parse_num( "${num}e+6", ".", "_" );
        ok( ( $s == $st and $i == "999999999999" and $f eq 0 and $e == 0 ), "parse_num G" );

        ( $s, $i, $f, $e ) = Lingua::ES::Numeros::parse_num( "${num}e+9", ".", "_" );
        ok( ( $s == $st and $i == "999999999999" and $f eq 0 and $e == 3 ), "parse_num H" );
    }
}

sub simple_tests {
    my $obj = Lingua::ES::Numeros->new();

    # Check for proper XHTML entity names, testscase for bug #69323
    # thanks to "Eduardo Tubert" <eatubert@insoft.com.mx>
    $obj->acentos(1);
    ok($obj->cardinal(16016) eq "dieciséis mil dieciséis", "Lowercase text with accents");
    $obj->mayusculas( 1 );
    ok($obj->cardinal(16016) eq "DIECISÉIS MIL DIECISÉIS", "Uppercase text with accents");
    $obj->mayusculas( 0 );
    $obj->html(1);
    ok($obj->cardinal(16016) eq "diecis&eacute;is mil diecis&eacute;is", "Lowercase XHTML");
    $obj->mayusculas( 1 );
    ok($obj->cardinal(16016) eq "DIECIS&Eacute;IS MIL DIECIS&Eacute;IS", "Uppercase XHTML");
    $obj->mayusculas( 0 );
}

accesors;
parser;
simple_tests;
