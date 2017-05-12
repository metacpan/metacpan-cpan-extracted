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
use Deep::Encode qw(deep_utf8_off deep_utf8_upgrade deep_utf8_downgrade deep_utf8_check);

my $s1 = chr(1);

for my $t ( 
	'deep_utf8_off( $_ = chr(1) ) == 0',
	'deep_utf8_off( $_ = chr(256) ) == 1',
	'deep_utf8_off( $_ = [ chr(1), chr(256), chr(257)] ) == 2',
	){
    local $_;
    ok( scalar eval $t, $t);
}
for my $t ( 
	'deep_utf8_upgrade( $_ = chr(1) ) == 1',
	'deep_utf8_upgrade( $_ = chr(256) ) == 0',
	'deep_utf8_upgrade( $_ = [ chr(1), chr(256), chr(257)] ) == 1',
	'deep_utf8_upgrade( $_ = [ chr(1), chr(2), chr(257)] ) == 2',
	){
    local $_;
    ok( scalar eval $t, $t);
}


for my $t ( 
	'deep_utf8_downgrade( $_ = chr(1) ) == 0',
	'deep_utf8_downgrade( $_ = chr(128) ) == 0',
	'deep_utf8_downgrade( $_ = mychr(2) ) == 1',
	'deep_utf8_downgrade( $_ = mychr(128) ) == 1',
	'deep_utf8_downgrade( $_ = [ chr(1), chr(2), mychr(1), mychr(2) ]) == 2 ',
	){
    local $_;
    ok( scalar eval $t, $t);
}
is(scalar eval { deep_utf8_downgrade( chr(256))}, undef, "fail downgrade");
sub mychr{
    my $x = shift;
    $x = chr $x;
    $x.= chr(256);
    chop $x;
    return $x;
}

my $x = chr(256);
my $y = $x;


utf8::encode( $y );
deep_utf8_off( $x );
ok( $y eq $x, "check off flag");
ok( $y ne chr(256), "check on flag" );

{{ # upgrade/downgrade
    my $orig = pack "C*", 0..255;
    my $x = $orig;
    my $y = $x;
    my $z = Encode::decode( 'latin1', $orig );
    utf8::upgrade( $y );
    my $res = deep_utf8_upgrade( $x );

    ok( $x eq $y , "deep_upgrade" );
    ok( $x eq $z , "deep_upgrade(latin1)" );
    is( $res, 1, "upgrade res");

    utf8::downgrade( $y );
    $res = deep_utf8_downgrade( $x );
    $z = Encode::encode( 'latin1', $z );

    

    ok( $x eq $y, "deep_downgrade" );
    ok( $x eq $z, "deep_downgrade latin1" );
    ok( $x eq $orig, "deep_downgrade orig");
    is( $res, 1, "downgrade res");



}};

ok( deep_utf8_check( pack("C*", 0..127)), "deep_utf8_check");
for ( 128 .. 255 ){
    my $x = pack("C*", $_);
    my $true = !deep_utf8_check( $x ) && ! deep_utf8_check(chr(127).$x) && ! deep_utf8_check($x . chr(127));
    ok( $true , "! deep_utf8_check($_)");
}
my $true_ok = 1;
my $message = '';

for (128 .. 0xB7FF){
    my $x = pack "U*", $_;
    utf8::encode( $x );
    chop( my $y = $x);

    my $true  = deep_utf8_check( $x ) && !deep_utf8_check( substr($x, 1)) &&!deep_utf8_check($y);

    $true_ok &&= $true;
    $message = "at $_ " unless $true;
    last unless $true;
};
ok( $true_ok , " deep_utf8_check(128..0xb7FF_) $message");

