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
use Test::More qw(no_plan);
#use ExtUtils::testlib;
use Deep::Encode qw(deep_utf8_off deep_utf8_upgrade deep_utf8_downgrade deep_utf8_check);

my $true_ok = 1;
my $message = '';
my $x = chr(23).chr(128);

ok( !deep_utf8_check( substr( $x, 1)), "regression magic");
ok( !deep_utf8_check( chr(128) ), "const chr (regression)");
