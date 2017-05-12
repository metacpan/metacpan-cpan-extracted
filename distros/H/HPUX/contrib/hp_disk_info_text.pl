#!/usr/bin/perl
#
# Copyright (C) 2001 Christopher White.  All rights reserved. This
#   program is free software;  you can redistribute it and/or modify it
#   under the same terms as perl itself.
#

use HPUX::LVM;
use HPUX::Ioscan;
use HPUX::FS;
use Getopt::Std;


format STDOUT2 =
 ================   =====================   ===========================
| Controller     | |         Disk        | | Lvol  : @<<<<<<<<<<<<<<<< |
                $lvolshow
|----------------| |-------------------- | | Mntpt : @<<<<<<<<<<<<<<<< |
                $mntpt
| @<<<<<<<<<<<<< | | @<<<<<<<<<<<<<<<<<< | | Stripe: @<<<< of @<<<<<   |
                $contr, $dsk, $stripe_index, $ordered_stripes_scalar
 ================   =====================  | PEonPV: @<<<<             |
                $disklvoldata{$lvol}->{pe_on_pv}
                                            ===========================
                $lvolshow
|----------------| |-------------------- | | Mntpt : @<<<<<<<<<<<<<<<< |
                $mntpt
| @<<<<<<<<<<<<< | | @<<<<<<<<<<<<<<<<<< | | Stripe: @<<<< of @<<<<<   |
                $contr, $dsk, $stripe_index, $ordered_stripes_scalar
 ================   =====================  | PEonPV: @<<<<             |
                $disklvoldata{$lvol}->{pe_on_pv}
                                            ===========================
.

format STDCONTRL =
 =================================================
| Controller : @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  |
        $contr
| Description: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  |
        $instance_desc
| Instance No: @<<                                |
        $instance
| Number of Disks: @<<                            |
        $number_of_disks_on_controller
 =================================================
.
format STDDISKSTART =
         =============START OF DISK================
        | Disk   : @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  |
                $dsk
        | Driver : @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  |
                $mydriver
        | Desc   : @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  |
                $mydesc
        | Links  : ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  |
                $tmplinks
        |          ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  |
                $tmplinks
        |          ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  |
                $tmplinks
         ==========================================
.
format STDDISKEND =
         ==============END OF DISK=================
        | Disk   : @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  |
                $dsk
        | Driver : @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  |
                $mydriver
        | Desc   : @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  |
                $mydesc
        | Total Used PE : @<<<<<<<<<<<<<<<<<<<<<<  |
                $total_pe_on_pv
        | Total Free PE : @<<<<<<<<<<<<<<<<<<<<<<  |
                $free_pe_on_pv
         ==========================================
.
format STDLVOL =
               |            ===========================
               |           | Lvol  : @<<<<<<<<<<<<<<<< |
                                        $lvolshow
               |           | Mntpt : @<<<<<<<<<<<<<<<< |
                                        $mntpt
               |           | Stripe: @<<<< of @<<<<<   |
                                        $stripe_index, $ordered_stripes_scalar
               |           | PEonPV: @<<<<             |
                                        $disklvoldata{$lvol}->{pe_on_pv}
               |            ===========================
.

$debug=0;
$debug5=0;
$debug6=0;
$debug8=0;
$debug9=0;

$tablecnt=0;
$maxentries=0;
$tableentries=0;
$tableentries_save=0;

getopt('h:r:m:l:v:p:');

$sub_system = $opt_h;
$sub_fshighlight = $opt_m;
$sub_rtype = $opt_r;
$sub_loc_data  = $opt_l   || '/tmp/lvminfo.dat';
$sub_show_empty  = $opt_v || 'no';
$sub_persist  = $opt_p || 'new';

$|=1;

# Create data structures

my $lvminfo_data = new HPUX::LVM(
                                target_type     =>"local",
                                persistance     =>"$sub_persist",
                                datafile        =>"$sub_loc_data",
                                access_prog     =>"$sub_rtype",
                                access_system   =>"$sub_system",
                                access_user     =>"root"
                                );

my $ioscan_data = new HPUX::Ioscan(
				target_type	=>"local",
				persistance	=>"$sub_persist",
				access_prog	=>"$sub_rtype",
				access_system	=>"$sub_system",
				access_user	=>"root",
				access_speed	=>"slow"
				);
my $fsinfo_data = new HPUX::FS(
				target_type	=>"local",
				persistance	=>"$sub_persist",
				access_prog	=>"$sub_rtype",
				access_system	=>"$sub_system",
				access_user	=>"root"
				);

#Get a hash of all the pvlinks (if any)

my $hashref = $lvminfo_data->get_all_pvlinks;
print "Alternate Link Hash Ref is: $hashref\n" if $debug8;
my %linkhash = %$hashref;

#End of alternate link hash generation

print "Get Controllers!\n" if $debug;

$arref = $ioscan_data->get_disk_controllers();

# start main table thats gonna hold tables in its cells
# using raw HTML to create main table.


CONTRLOOP: foreach $contr ( @$arref )      {
	$maxentries=0;
        print "Controller: $contr\n" if $debug;
#
#NEW Get controller information
#
	$instance = $ioscan_data->get_instance_number(
				hwpath => $contr
						);
	$instance_desc = $ioscan_data->get_description(
				hwpath => $contr
						);
	print "Instance: $instance\n" if $debug;
	print "Get Disks in controller $contr\n" if $debug;

	$arref2 = $ioscan_data->get_all_disks_on_controller	(
				controller	=>"$contr"
								);

	$number_of_disks_on_controller=scalar(@$arref2);

	if ( scalar(@$arref2) eq 0 and $sub_show_empty eq "no")	{
		print "No Devices on controller!\n" if $debug;
		next CONTRLOOP;
					}
#
#NEW Got controller information
#

#NEW Print Controller info Here
$~="STDCONTRL";
write;

	foreach $dsk ( @{ $arref2 } )	{
#
#NEW Get Disk Information Here!
#
			$myhwpath = $ioscan_data->get_device_hwpath(
				device_name	=> $dsk
							);
			print "Myhwpath = $myhwpath\n" if $debug6;
			$myclass  = $ioscan_data->get_class(
				hwpath => $myhwpath
							);
			$mydriver = $ioscan_data->get_driver(
				hwpath => $myhwpath
							);
			$mydesc   = $ioscan_data->get_description(
				hwpath => $myhwpath
							);
# Add alternate links to disk
if ( exists($linkhash{$dsk}) )	{
	   @links = @{ $linkhash{ $dsk } };
				}
else				{
	   @links="No Alternate Links";
				}
$tmplinks=join("  ", @links);
#
#NEW Got disk info
#

#NEW print start of disk info here
$~="STDDISKSTART";
write;

#
#NEW Get Lvol info
#
         	print "disk: $dsk\n" if $debug;
		$getlvoldata = $lvminfo_data->get_disk_lvol_data(

				device_name	=> "$dsk"
								);
		@check_keys = keys %$getlvoldata;
		print "Check_keys is: @check_keys\n" if $debug5;
		print "scalar check_keys is:".scalar(@check_keys)."\n" if $debug5;
		 %disklvoldata = %$getlvoldata;
		  @checklvols = (sort keys %disklvoldata);
		  print "Number of lvols: ",scalar(@checklvols),"\n" if $debug;
		  if ( scalar(@checklvols) < 1 )	{
			$total_pe_on_pv = "None";
							}
		  foreach $lvol ( sort keys %disklvoldata )	{
			$tableentries++;
			$lv_vg = $disklvoldata{$lvol}->{vg_on_pv};
			$total_pe_on_pv = $lvminfo_data->get_vg_physicalvol_attr(
					volume_group 	=> "$lv_vg",
			 		device_name	=> "$dsk",
			 		attribute	=> "Total_PE" 
								);
			$stripes_on_lv = $lvminfo_data->get_vg_lvol_attr_lvdisplay(
					volume_group	=> "$lv_vg",
					logical_vol	=> "$lvol",
					attribute	=> "Stripes"
								);
			print "Total PE On PV=$total_pe_on_pv\n" if $debug;
			print "Volume Group: $lv_vg\n" if $debug;
			$lvolshow = $lv_vg.'/'.$lvol;
			print "Logical Vol: $lvol\n" if $debug;
			$mntpt = $fsinfo_data->get_filesystem_attr(
				filesystem	=> "$lvolshow",
				attribute	=> 'directory'
								);
			if ( $stripes_on_lv gt 0 )	{
#If stripes then do something useful
			$ordered_stripes_arr_ref = $lvminfo_data->get_vg_lvol_stripeorder(
					volume_group	=> "$lv_vg",
					logical_vol	=> "$lvol"
								);
			@ordered_stripes = @$ordered_stripes_arr_ref;
			$stripe_index=0;
			for ($i = 0; $i< @ordered_stripes ; $i++ ) 	{
				print "Ordered_stripes: $ordered_stripes[$i]\n" if $debug9;
				print "dsk: $dsk\n" if $debug9;
				if ( $ordered_stripes[$i] eq $dsk )	{
					$stripe_index=$i+1;
								}	
									}
				$ordered_stripes_scalar = scalar(@ordered_stripes);
				$mntpt=$mntpt.'(Stripe '.$stripe_index.' of '.$ordered_stripes_scalar;
							}
			if ( $mntpt eq "$sub_fshighlight" && $sub_fshighlight ne "" )	{
				$mntpt = '<FONT COLOR=RED>'.$mntpt.'</FONT>';
								}
			print "  le_on_pv: $disklvoldata{$lvol}->{le_on_pv}\n" if $debug;
			print "  pe_on_pv: $disklvoldata{$lvol}->{pe_on_pv}\n" if $debug;
			$used_by_lv = $disklvoldata{$lvol}->{pe_on_pv};
			$used_pe = $used_pe + $disklvoldata{$lvol}->{pe_on_pv};
$~="STDLVOL";
write;
								}

	$tableentries_save = $tableentries;
if ($maxentries < $tableentries)	{
	print "TableEntries is: $tableentries\n" if $debug;
	$maxentries = $tableentries;
	print "Maxentries is now!: $maxentries\n" if $debug;
					}
	$tableentries=0;
	
	$free_pe_on_pv = $total_pe_on_pv - $used_pe;
	$used_pe="";

		if (scalar(@check_keys) == 0 )	{
			print "No LVM found on this\n" if $debug5;
			print "Adding 1 to maxentries\n" if $debug;
			print "Makeing tableenties_save 1\n" if $debug;
			$tableentries_save=1;
			$dsk = $dsk.' (NOT IN LVM)';
#Add Disk Alternate Link Check Here
	print "Just added ending stuff to non lvm table\n" if $debug;
						}
$~="STDDISKEND";
write;
		print "MaxEntries: $maxentries\n" if $debug;
					}
                                }
