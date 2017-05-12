# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $main::loaded;}

use HPUX::LVM;
$loaded = 1;

my $idx = 1;
print "ok ",$idx++,"\n";

$pvinvg="";

# Create data structures

my $lvminfo_data = new HPUX::LVM(
			persistance	=> "old",
			datafile   	=> "./t/vginfo.dat"
				);
print "ok ",$idx++,"\n";
#print "\n\nTesting LVMInfo.pm\n\n";

$arref2 = $lvminfo_data->get_all_volumegroups();

foreach $vg (@$arref2)	{
#	print "Volume Group: $vg\n";
	$vg_save = $vg;
			}
$arref2a = $lvminfo_data->get_vg_physicalvols(
			volume_group	=> $vg_save
					);

#print "Physical vols in vg: $vg_save\n";
foreach $pvinvg (@$arref2a)	{
#	print "$pvinvg\n";
				}
print "ok ",$idx++,"\n";

$arref2b = $lvminfo_data->get_vg_lvols(
			volume_group	=> $vg_save
					);

print "ok ",$idx++,"\n";
#print "Logical Volumes in vg: $vg_save\n";

foreach $lvinvg (@$arref2b)	{
#	print "$lvinvg\n";
	$lvinvg_save = $lvinvg;
				}

#print "Logical Volume attributes per VGDISPLAY of lv $lvinvg_save VG: $vg_save\n";
print "ok ",$idx++,"\n";

$attr1 =$lvminfo_data->get_vg_lvol_attr_vgdisplay(
	volume_group	=> $vg_save,
	logical_vol	=> $lvinvg_save,
	attribute	=> "Allocated_PE",
				 );
$attr2 =$lvminfo_data->get_vg_lvol_attr_vgdisplay(
	volume_group	=> $vg_save,
	logical_vol	=> $lvinvg_save,
	attribute	=> 'Current_PE'
				 );
$attr3 =$lvminfo_data->get_vg_lvol_attr_vgdisplay(
	volume_group	=> $vg_save,
	logical_vol	=> $lvinvg_save,
	attribute	=> LV_Size
				 );
$attr4 =$lvminfo_data->get_vg_lvol_attr_vgdisplay(
	volume_group	=> $vg_save,
	logical_vol	=> $lvinvg_save,
	attribute	=> 'LV_Status'
				 );
$attr5 =$lvminfo_data->get_vg_lvol_attr_vgdisplay(
	volume_group	=> $vg_save,
	logical_vol	=> $lvinvg_save,
	attribute	=> 'Used_PV'
				 );


print "ok ",$idx++,"\n";
#print "Logical Volume attributes per LVDISPLAY of lv $lvinvg_save VG: $vg_save\n";

$attr1 =$lvminfo_data->get_vg_lvol_attr_lvdisplay(
        volume_group    => "$vg_save",
        logical_vol     => "$lvinvg_save",
        attribute       => "Allocation"
                                 );
$attr2 =$lvminfo_data->get_vg_lvol_attr_lvdisplay(
        volume_group    => $vg_save,
        logical_vol     => $lvinvg_save,
        attribute       => LV_Permission
                                 );
$attr3 =$lvminfo_data->get_vg_lvol_attr_lvdisplay(
        volume_group    => $vg_save,
        logical_vol     => $lvinvg_save,
        attribute       => LV_Size_Mbytes
                                 );
$attr4 =$lvminfo_data->get_vg_lvol_attr_lvdisplay(
        volume_group    => $vg_save,
        logical_vol     => $lvinvg_save,
        attribute       => Stripes
                                 );
$attr5 =$lvminfo_data->get_vg_lvol_attr_lvdisplay(
        volume_group    => $vg_save,
        logical_vol     => $lvinvg_save,
        attribute       => Schedule
                                 );

print "ok ",$idx++,"\n";
