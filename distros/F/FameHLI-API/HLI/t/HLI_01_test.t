#=============================================================================
#	File:	HLI_01_test.t
#	Author:	Dave Oberholtzer, (daveo@obernet.com)
#			Copyright (c)2005, David Oberholtzer.
#	Date:	2001/03/23
#	Use:	Testing file for FameHLI::HLI 'variables'
#=============================================================================
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use FameHLI::API::HLI ':all';
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# This doesn't really do much.  But then, there really isn't that
#	much to test.  Can if find a CONSTANT or not?
# The ND stuff doesn't work yet.

open (LOG, ">HLI_01_test.log");
print("not ") unless (HBUSNS eq 9);
print("ok 2\n");
printf(LOG "HBUSNS is '%d'\n", HBUSNS);
printf(LOG "FPRCND is '%g' (broken)\n", FPRCND);
printf(LOG "FNUMND is '%g' (broken)\n", FNUMND);
close(LOG);
