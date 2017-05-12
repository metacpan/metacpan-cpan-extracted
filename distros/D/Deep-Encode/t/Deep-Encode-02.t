#
#===============================================================================
#
#         FILE:  Deep-Encode-01.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Grishaev Anatoliy (ga), zua.zuz@toh.ru
#      COMPANY:  Adeptus, Russia
#      VERSION:  1.0
#      CREATED:  09/20/10 13:56:34
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use Test::More 'no_plan';                      # last test to print
#use ExtUtils::testlib;
use Deep::Encode;
use Encode qw(from_to encode decode);

my $cp1251_str = "cp1251";
my $cp1251_obj = Encode::find_encoding( $cp1251_str );

my $patt1 = join "", map chr, 0..127;
my $patt2 = join "", map chr, 0..255;

my $patt1_utf = decode(  $cp1251_str , $patt1 );
my $patt2_utf = decode(  $cp1251_str , $patt2 );

for my $s1 ( $patt1 ){
    my $s2 = $s1;
    my $s3 = $s1;
    my $utf8 =   decode( $cp1251_str , $s1 );
    deep_decode( $s2, $cp1251_str );
    deep_decode( $s3, $cp1251_obj );
    ok ( $utf8 eq $s2, " deep_decode (ascii) ");
    ok ( $utf8 eq $s3, " deep_decode (ascii) ");
}

for my $s1 ( $patt2 ){
    my $s2 = $s1;
    my $s3 = $s1;
    my $utf8 =   decode( $cp1251_str , $s1 );
    deep_decode( $s2, $cp1251_str );
    deep_decode( $s3, $cp1251_obj );
    ok ( $utf8 eq $s2, " deep_decode (full) ");
    ok ( $utf8 eq $s3, " deep_decode (full) ");
}

for my $s1 ( $patt1_utf ){
    my $s2 = $s1;
    my $s3 = $s1;
    my $s4 = $s1;
    my $s5 = $s1;
    my $s0 = $s1;
    my $cp =   encode( $cp1251_str , $s1 );
    deep_encode( $s2, $cp1251_str );
    deep_encode( $s3, $cp1251_obj );
    $s0 = encode( $cp1251_str, $s1 );

    utf8::encode( $_ ) for $s4, $s5;
    deep_from_to( $s4, 'utf8', $cp1251_str );
    deep_from_to( $s5, 'utf8', $cp1251_obj );

    ok ( $s2 eq $patt1, " deep_encode (ascii) ");
    ok ( $s3 eq $patt1, " deep_encode (ascii) ");
    is ( $s4, $s0, " deep_from_to (ascii) ");
    is ( $s5, $s0, " deep_from_to (ascii) ");
}

for my $s1 ( $patt2_utf ){
    my $s2 = $s1;
    my $s3 = $s1;
    my $s4 = $s1;
    my $s5 = $s1;
    my $s0 = $s1;
    my $cp =   encode( $cp1251_str , $s1 );
    deep_encode( $s2, $cp1251_str );
    deep_encode( $s3, $cp1251_obj );
    $s0 = encode( $cp1251_str, $s1 );

    utf8::encode( $_ ) for $s4, $s5;

    deep_from_to( $s4, 'utf8', $cp1251_str );
    deep_from_to( $s5, 'utf8', $cp1251_obj );

    is ( $s2, $s0, " deep_encode (full) ");
    is ( $s3, $s0, " deep_encode (full) ");
    is ( $s4, $s0, " deep_from_to (full) ");
    is ( $s5, $s0, " deep_from_to (full) ");
}




