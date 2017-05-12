#!/usr/bin/perl
use Linux::LVM;
Linux::LVM->units('G');
# Date: 2012-02-08
%vg = get_volume_group_information("vg00");

print "--- Volume group --- \n";
printf("%-20s %-s\n","VG Name",$vg{vgname});
printf("%-20s %-s\n","VG Access",$vg{access});
printf("%-20s %-s\n","VG Status",$vg{status});
printf("%-20s %-s\n","VG #",$vg{vg_number});
printf("%-20s %-s\n","MAX LV",$vg{max_lv});
printf("%-20s %-s\n","Cur LV",$vg{cur_lv});
printf("%-20s %-s\n","Open LV",$vg{open_lv});
printf("%-20s %-s %-s\n","MAX LV Size",$vg{max_lv_size},$vg{max_lv_size_unit});
printf("%-20s %-s\n","MAX PV",$vg{max_pv});
printf("%-20s %-s\n","Cur PV",$vg{cur_pv});
printf("%-20s %-s\n","Act PV",$vg{act_pv});
printf("%-20s %-s %-s\n","VG Size",$vg{vg_size},$vg{vg_size_unit});
printf("%-20s %-s %-s\n","PE Size",$vg{pe_size},$vg{pe_size_unit});
printf("%-20s %-s\n","Total PE",$vg{total_pe});
printf("%-20s %-s / %-s %-s\n","Alloc PE / Size",$vg{alloc_pe},$vg{alloc_pe_size},$vg{alloc_pe_size_unit});
printf("%-20s %-s / %-s %-s\n","Free  PE / Size",$vg{free_pe},$vg{free_pe_size},$vg{free_pe_size_unit});
printf("%-20s %-s\n","VG UUID",$vg{uuid});
print "\n";

