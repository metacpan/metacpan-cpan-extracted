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
use Deep::Encode qw(deep_str_clone deepc_utf8_encode);
use Scalar::Util qw(refaddr);


my $wide=chr(128);
my $xwide = chr(20000);
my $beep = "abc";
my $s = [ 0, undef, "abc", $beep, $wide, $xwide, chr(128 ), [$wide]];
my $m = deep_str_clone( $s );

ok( a_equal( \$s->[0], \$m->[0]), "s[0]");
ok( a_equal( \$s->[1], \$m->[1]), "s[1]");
#ok( a_equal( \$s->[2], \$m->[2]), "s[2]");
#ok( a_equal( \$s->[3], \$m->[3]), "s[3]");

ok( !a_equal( \$s->[4], \$m->[4]), "s[4]");
ok( !a_equal( \$s->[5], \$m->[5]), "s[5]");
ok( !a_equal( \$s->[6], \$m->[6]), "s[6]");
ok( !a_equal( \$s->[7], \$m->[7]), "s[7]");



sub a_equal{
	refaddr( $_[0] ) == refaddr( $_[1] );
}

