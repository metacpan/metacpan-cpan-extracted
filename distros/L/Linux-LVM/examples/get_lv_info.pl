#!/usr/bin/perl
use Linux::LVM;
Linux::LVM->units('G');
# Date: 2012-02-08
%hash = get_lv_info("/dev/vg00/software");

foreach(sort keys %hash) {
    print "$_ = $hash{$_} \n";
}
