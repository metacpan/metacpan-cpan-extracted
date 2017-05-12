#!/usr/bin/perl -w
#
#  Copyright (C) 2006, 2008, 2011 Rocky Bernstein <rocky@cpan.org>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Program to read CD blocks. See read-cd from the libcdio distribution
# for a more complete program.

BEGIN {
    chdir 'example' if -d 'example';
    use lib '../lib';
    eval "use blib";  # if we fail keep going - maybe we have installed Cdio
}

use Device::Cdio;
use Device::Cdio::Device;

use vars qw($0 $program $pause %opts);

use strict;

# Prints out drive capabilities
sub print_drive_capabilities($$$) {
    my ($i_read_cap, $i_write_cap, $i_misc_cap) = @_;
  if ($i_misc_cap->{DRIVE_CAP_ERROR}) {
    printf("Error in getting drive hardware properties\n");
  } else {
    printf("Hardware                    : %s\n", 
	   $i_misc_cap->{DRIVE_CAP_MISC_FILE}  
	   ? "Disk Image"  : "CD-ROM or DVD");
    printf("Can eject                   : %s\n", 
	   $i_misc_cap->{DRIVE_CAP_MISC_EJECT}
	   ? "Yes" : "No");
    printf("Can close tray              : %s\n", 
	   $i_misc_cap->{DRIVE_CAP_MISC_CLOSE_TRAY}
	   ? "Yes" : "No");
    printf("Can disable manual eject    : %s\n", 
	   $i_misc_cap->{DRIVE_CAP_MISC_LOCK}          
	   ? "Yes" : "No");
    printf("Can select juke-box disc    : %s\n\n", 
	   $i_misc_cap->{DRIVE_CAP_MISC_SELECT_DISC}   
	   ? "Yes" : "No");

    printf("Can set drive speed         : %s\n", 
	   $i_misc_cap->{DRIVE_CAP_MISC_SELECT_SPEED}  
	   ? "Yes" : "No");
# Don't think this bit is set accurately. 
#    printf("Can detect if CD changed    : %s\n", 
#	   $i_misc_cap->{DRIVE_CAP_MISC_MEDIA_CHANGED} 
#	   ? "Yes" : "No");
    printf("Can read multiple sessions  : %s\n", 
	   $i_misc_cap->{DRIVE_CAP_MISC_MULTI_SESSION} 
	   ? "Yes" : "No");
    printf("Can hard reset device       : %s\n\n", 
	   $i_misc_cap->{DRIVE_CAP_MISC_RESET}         
	   ? "Yes" : "No");
  }
  
    
  if ($perlcdio::DRIVE_CAP_ERROR == $i_read_cap) {
      printf("Error in getting drive reading properties\n");
  } else {
    printf("Reading....\n");
    printf("  Can play audio            : %s\n", 
	   $i_read_cap->{DRIVE_CAP_READ_AUDIO}      
	   ? "Yes" : "No");
    printf("  Can read  CD-DA           : %s\n", 
	   $i_read_cap->{DRIVE_CAP_READ_CD_DA}       
	   ? "Yes" : "No");
    printf("  Can read  CD+G            : %s\n", 
	   $i_read_cap->{DRIVE_CAP_READ_CD_G}       
	   ? "Yes" : "No");
    printf("  Can read  CD-R            : %s\n", 
	   $i_read_cap->{DRIVE_CAP_READ_CD_R}       
	   ? "Yes" : "No");
    printf("  Can read  CD-RW           : %s\n", 
	   $i_read_cap->{DRIVE_CAP_READ_CD_RW}      
	   ? "Yes" : "No");
    printf("  Can read  DVD-R           : %s\n", 
	   $i_read_cap->{DRIVE_CAP_READ_DVD_R}    
	   ? "Yes" : "No");
    printf("  Can read  DVD+R           : %s\n", 
	   $i_read_cap->{DRIVE_CAP_READ_DVD_PR}    
	   ? "Yes" : "No");
    printf("  Can read  DVD-RAM         : %s\n", 
	   $i_read_cap->{DRIVE_CAP_READ_DVD_RAM}    
	   ? "Yes" : "No");
    printf("  Can read  DVD-ROM         : %s\n", 
	   $i_read_cap->{DRIVE_CAP_READ_DVD_RW}    
	   ? "Yes" : "No");
    printf("  Can read  DVD-ROM         : %s\n", 
	   $i_read_cap->{DRIVE_CAP_READ_DVD_RPW}    
	   ? "Yes" : "No");
    printf("  Can read  DVD+RW          : %s\n", 
	   $i_read_cap->{DRIVE_CAP_READ_DVD_ROM}    
	   ? "Yes" : "No");
    printf("  Can read C2 Errors        : %s\n", 
	   $i_read_cap->{DRIVE_CAP_READ_C2_ERRS}    
	   ? "Yes" : "No");
    printf("  Can read MODE 2 FORM 1    : %s\n", 
	   $i_read_cap->{DRIVE_CAP_READ_MODE2_FORM1}    
	   ? "Yes" : "No");
    printf("  Can read MODE 2 FORM 2    : %s\n", 
	   $i_read_cap->{DRIVE_CAP_READ_MODE2_FORM2}    
	   ? "Yes" : "No");
    printf("  Can read MCN              : %s\n", 
	   $i_read_cap->{DRIVE_CAP_READ_MCN}    
	   ? "Yes" : "No");
    printf("  Can read ISRC             : %s\n", 
	   $i_read_cap->{DRIVE_CAP_READ_ISRC}    
	   ? "Yes" : "No");
  }
  

  if ($perlcdio::DRIVE_CAP_ERROR == $i_write_cap) {
      printf("Error in getting drive writing properties\n");
  } else {
    printf("\nWriting....\n");
    printf("  Can write CD-RW           : %s\n", 
	   $i_read_cap->{DRIVE_CAP_WRITE_CD_RW}     ? "Yes" : "No");
    printf("  Can write DVD-R           : %s\n", 
	   $i_write_cap->{DRIVE_CAP_WRITE_DVD_R}    ? "Yes" : "No");
    printf("  Can write DVD-RAM         : %s\n", 
	   $i_write_cap->{DRIVE_CAP_WRITE_DVD_RAM}  ? "Yes" : "No");
    printf("  Can write DVD-RW          : %s\n", 
	   $i_write_cap->{DRIVE_CAP_WRITE_DVD_RW}   ? "Yes" : "No");
    printf("  Can write DVD-R+W         : %s\n", 
	   $i_write_cap->{DRIVE_CAP_WRITE_DVD_RPW}  ? "Yes" : "No");
    printf("  Can write Mt Rainier      : %s\n", 
	   $i_write_cap->{DRIVE_CAP_WRITE_MT_RAINIER}? "Yes" : "No");
    printf("  Can write Burn Proof      : %s\n", 
	   $i_write_cap->{DRIVE_CAP_WRITE_BURN_PROOF}? "Yes" : "No");
  }
}

my ($d, $drive_name);

if ($ARGV[0]) {
    $drive_name=$ARGV[0];
    $d = Device::Cdio::Device->new(-source=>$drive_name);
    if (!defined($drive_name)) {
	print "Problem opening CD-ROM: $drive_name\n";
	exit(1);
    }
} else {
    $d = Device::Cdio::Device->new(-driver_id=>$perlcdio::DRIVER_DEVICE);
    $drive_name = $d->get_device();
    if (!defined($drive_name)) {
        print "Problem finding a CD-ROM\n";
        exit(1);
    }
}
        
my ($vendor, $model, $release, $drc) = $d->get_hwinfo();

print "drive: $drive_name, vendor: $vendor, " .
    "model: $model, release: $release\n";

my ($i_read_cap, $i_write_cap, $i_misc_cap) =  $d->get_drive_cap();
print_drive_capabilities($i_read_cap, $i_write_cap, $i_misc_cap);


print "\nDriver Availabiliity...\n";

foreach my $driver_name (sort keys(%Device::Cdio::drivers)) {
    print "Driver $driver_name is installed.\n"
	if Device::Cdio::have_driver($driver_name) and
	$driver_name !~ m{device|Unknown};
}
$d->close();
