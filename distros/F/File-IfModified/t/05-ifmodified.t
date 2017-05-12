#===============================================================================
#
#         FILE:  05-ifmodified.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  08/11/2011 03:53:41 PM
#     REVISION:  ---
#===============================================================================
use strict;
use Test::More no_plan => ;                      # last test to print


use_ok( 'File::IfModified' );
use_ok( 'File::IfModified', 'if_modified' );
use_ok( 'File::IfModified', 'touch' );
use_ok( 'File::IfModified', 'vtouch' );
use_ok( 'File::IfModified', 'vtouch_all' );
mkdir "t/tmp";
unlink my $test = "t/tmp/if_mod.tmp";

ok( if_modified( $test ), "first on empty" );
ok( if_modified( $test ), "secornd on empty" );

touch( $test );
ok( -e $test, "touch create file" );


ok( if_modified( $test ), "first on exists" );
ok( ! if_modified( $test ), "secornd on exists" );
#sleep 2;
touch( $test );
ok(  if_modified( $test ), "secornd on exists and after touch" );
ok( ! if_modified( $test ), "secornd on exists and touch" );
unlink $test;
ok(  if_modified( $test ), "secornd on exists and ... delete" );
vtouch( $test );
ok( if_modified( $test ), "vtouch" );
vtouch_all( if_modified( $test ));

ok( if_modified( $test ), "vtouch_all" );


# Cleanup temporaty garbage 
unlink $test;
rmdir "t/tmp";
