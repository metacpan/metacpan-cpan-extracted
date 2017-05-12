#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  cpus.pl
#
#        USAGE:  ./cpus.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Jillian Rowe (), jir2004@qatar-med.cornell.edu
#      COMPANY:  Weill Cornell Medical College Qatar
#      VERSION:  1.0
#      CREATED:  26/02/15 13:38:54
#     REVISION:  ---
#===============================================================================

package Main;

use Moose;
use Sys::Info;
use Sys::Info::Constants qw( :device_cpu );

extends 'HPC::Runner::Node';

my $self = Main->new_with_options()->go;
