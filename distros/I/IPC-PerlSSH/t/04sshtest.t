#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;

use IPC::PerlSSH;

if( !$ENV{I_CAN_SSH_LOCALHOST} ) {
   print STDERR <<EOF;

#############################################################################
# This test script relies on the ability to "ssh localhost perl" without    #
# entering a password/passphrase, or agreeing to the host key. In most      #
# automated test environments this will not be the case.                    #
#                                                                           #
# To enable this test, set the environment variable I_CAN_SSH_LOCALHOST to  #
# some true value before running 'make test'                                #
#############################################################################
EOF

   ok( 1, "skipping" );
   ok( 1, "skipping" );
}

else {
   my $ips = IPC::PerlSSH->new( Host => "localhost" );
   ok( defined $ips, "Constructor" );

   # Test basic eval / return
   my $result = $ips->eval( '( 10 + 30 ) / 2' );
   is( $result, 20, "Scalar eval return" );
}
