#
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
use Test::More qw(no_plan);
#use ExtUtils::testlib;
use Deep::Encode qw(deep_utf8_off deep_utf8_upgrade deep_utf8_downgrade deep_utf8_check deep_utf8_encode);

my $a = substr( "a" . chr(1024), 0, 1);
ok( utf8::is_utf8( $a ));
deep_utf8_encode( $a );
ok( !utf8::is_utf8( $a ));
