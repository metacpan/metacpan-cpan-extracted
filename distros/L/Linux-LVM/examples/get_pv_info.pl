#!/usr/bin/perl
use Linux::LVM;
Linux::LVM->units('G');
use Data::Dumper;
 
%hash = get_pv_info("/dev/hdd1");

print Dumper(\%hash);

foreach(sort keys %hash) {
    print "$_ = $hash{$_} \n";
}
