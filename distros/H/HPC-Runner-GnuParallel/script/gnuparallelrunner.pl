#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  gnparallelrunner.pl
#
#        USAGE:  ./gnparallelrunner.pl  
#
#  DESCRIPTION:  Run a command from stream for logging and whatnot
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Jillian Rowe (), jir2004@qatar-med.cornell.edu
#      COMPANY:  Weill Cornell Medical College Qatar
#      VERSION:  1.0
#      CREATED:  30/03/15 15:21:55
#     REVISION:  ---
#===============================================================================

package Main;

use Moose;
extends 'HPC::Runner::GnuParallel';

Main->new_with_options()->go;

1;

