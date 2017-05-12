
######################################################################
#
#   Directory Digest -- test_config.pl
#   Matthew Gream (MGREAM) <matthew.gream@pobox.com>
#   Copyright 2002 Matthew Gream. All Rights Reserved.
#   $Id: test_config.pl,v 0.90 2002/10/21 20:24:06 matt Exp matt $
#
#   Test configuration 
#    
######################################################################


###########################################################################

$dirgest_cli = './dirgest.pl';
$dirgest_cgi = './dirgest.cgi';

my $TEST_QUIET = 1;
my $TEST_VERSION = "0.90";

###########################################################################

sub test_config_version { return $TEST_VERSION; }
sub test_config_quiet { return $TEST_QUIET; }
sub test_config_exec_cli { return $dirgest_cli; }
sub test_config_exec_cgi { return $dirgest_cgi; }

###########################################################################

1;
