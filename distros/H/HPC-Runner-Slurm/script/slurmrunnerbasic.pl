#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  slurmrunner.pl
#
#        USAGE:  ./slurmrunner.pl  
#
#  DESCRIPTION: Run jobs using slurm job queing system 
#               slurmrunner.pl --infile `pwd`/example/testcommand.in --outdir `pwd`/example/outslurm --jobname test
#
#===============================================================================

package Main;

use Moose;

extends 'HPC::Runner::Slurm';

Main->new_with_options()->run;

1;
