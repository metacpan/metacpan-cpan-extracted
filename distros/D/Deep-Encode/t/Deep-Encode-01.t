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

for my $s1 ( join("", map chr, 0..127) ){
    my $s2 = $s1;
    utf8::decode( $s1 );
    deep_utf8_decode( $s2 );
    ok(  $s1 eq $s2, "ok deep_utf8_decode (ascii)" );
};
for my $s1 ( join("", map chr, 0..1024) ){
    utf8::encode( $s1 );
    my $s2 = $s1;
    utf8::decode( $s1 );
    deep_utf8_decode( $s2 );
    ok(  $s1 eq $s2, "ok deep_utf8_decode (1024)" );
};
for my $s1 ( join("", map chr, 0..127) ){
    my $s2 = $s1;
    utf8::encode( $s1 );
    deep_utf8_encode( $s2 );
    ok(  $s1 eq $s2, "ok deep_utf8_encode (127)" );
};

for my $s1 ( join("", map chr, 0..1024) ){
    my $s2 = $s1;
    utf8::encode( $s1 );
    deep_utf8_encode( $s2 );
    ok(  $s1 eq $s2, "ok deep_utf8_encode (1024)" );
};



