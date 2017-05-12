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

use Sys::Info;
use Sys::Info::Constants qw( :device_cpu );

my $info = Sys::Info->new;
my %options;
my $cpu  = $info->device( CPU => %options );

printf "CPU: %s\n", scalar($cpu->identify)  || 'N/A';
printf "CPU speed is %s MHz\n", $cpu->speed || 'N/A';
printf "There are %d CPUs\n"  , $cpu->count || 1;
printf "CPU load: %s\n"       , $cpu->load  || 0;

if($cpu->ht){
    print "CPU hyperthreading enabled\n";
    printf "CPU hyperthreading: %s\n"       , $cpu->ht;
}
else{
    print "CPU hyperthreading not enabled\n";
}
