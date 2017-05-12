#===============================================================================
#
#         FILE:  Deep-Encode-05.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  01/27/2011 01:50:25 PM
#     REVISION:  ---
#===============================================================================


use strict;
use warnings;
no warnings 'uninitialized';
use Test::More qw(no_plan);
#use ExtUtils::testlib;
use Deep::Encode qw(deepc_from_to deepc_decode deepc_encode);
use Scalar::Util qw(refaddr);

my $de = Encode::encode_utf8(Encode::decode( 'cp1251', my $en = chr(192)));

print $de,"\n";
is( $de, deepc_from_to( $en, 'cp1251', 'utf8' ));
is( $en , chr(192) );
is( $en, deepc_from_to( $de, 'utf8', 'cp1251' ));
ok( $en ne $de  );





sub a_equal{
	refaddr( $_[0] ) == refaddr( $_[1] );
}

