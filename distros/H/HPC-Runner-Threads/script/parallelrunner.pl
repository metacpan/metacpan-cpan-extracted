#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  parallelrunner.pl
#
#        USAGE:  ./parallelrunner.pl  
#
#  DESCRIPTION: Run jobs using threads 
#===============================================================================

package Main;

use Moose;
extends 'HPC::Runner::Threads';

Main->new_with_options()->go;

1;
