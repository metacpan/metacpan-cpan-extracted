#!perl
use strict;
use ExtUtils::FindFunctions;

# This is a reduced example of how ExtUtils::FindFunctions is used inside 
# Net::Pcap (from which it was in fact factored out).

my @funcs_to_check = qw(
    pcap_findalldevs  pcap_open_dead  pcap_setnonblock  pcap_lib_version
);

my @avail_funcs = have_functions(libs => '-lpcap', funcs => \@funcs_to_check, return_as => 'array');

print "available functions: @avail_funcs\n";
