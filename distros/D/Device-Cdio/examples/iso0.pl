#!/usr/bin/perl -w
#
#  Copyright (C) 2006, 2011 Rocky Bernstein <rocky@cpan.org>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# A simple program to show using libiso9660 to list files in a directory of
#   an ISO-9660 image.
#
#   If a single argument is given, it is used as the ISO 9660 image to
#   use in the listing. Otherwise a compiled-in default ISO 9660 image
#   name (that comes with the libcdio distribution) will be used.

use strict;

BEGIN {
    chdir 'example' if -d 'example';
    use lib '../lib';
    eval "use blib";  # if we fail keep going - maybe we have installed Cdio
}

use Device::Cdio;
use Device::Cdio::Device;
use Device::Cdio::ISO9660;
use Device::Cdio::ISO9660::FS;
use File::Spec;

# The default ISO 9660 cue/bin file if none given
my $ISO9660_IMAGE_PATH="../data";
my $ISO9660_cd=File::Spec->catfile($ISO9660_IMAGE_PATH, "isofs-m1.cue");

my $cd_image_fname = $ISO9660_cd;
$cd_image_fname = $ARGV[0] if @ARGV >= 1;

my $iso = Device::Cdio::ISO9660::FS->new(-source=>$cd_image_fname);
  
if (!defined($iso)) {
    printf "Sorry, couldn't open %s as an ISO-9660 image.\n", $cd_image_fname;
    exit 1;
}

my $path = '/';
my @file_stats = $iso->readdir($path);

my $id = $iso->read_superblock();
printf "Super block: %s\n", $id if defined($id);

my $pvd = $iso->read_pvd();
printf "Super block: %s\n", $pvd if defined($pvd);

$id = perliso9660::get_application_id($pvd);
printf "Application ID: %s\n", $id if defined($id);

$id = perliso9660::get_preparer_id($pvd);
printf "Preparer ID: %s\n", $id if defined($id);

$id = perliso9660::get_publisher_id($pvd);
printf "Publisher ID: %s\n", $id if defined($id);

$id = perliso9660::get_system_id($pvd);
printf "System ID: %s\n", $id if defined($id);

$id = perliso9660::get_volume_id($pvd);
printf "Volume ID: %s\n", $id if defined($id);

$id = perliso9660::get_volumeset_id($pvd);
printf "Volumeset ID: %s\n", $id if defined($id);
print "\nfile_stats with ISO9660::name_translate\n";
foreach my $href (@file_stats) {    
    printf "%s [LSN %6d] %8d %s%s\n", 
    $href->{is_dir} ? "d" : "-",
    $href->{LSN}, $href->{size},
    $path,
    Device::Cdio::ISO9660::name_translate($href->{filename});
}

print "readdir \"/\"\n";
my @iso_stat = $iso->readdir ("/");
foreach my $i (@iso_stat) {
    #while(my ($k,$v) = each (%$i)) {
    #    print " $k => \"$v\",";
    #}
    printf "%s [LSN %6d] [secs %4d] %9d ",
    $i->{is_dir}?'d':' ',$i->{LSN},$i->{sec_size},$i->{size};
    print $i->{filename},"\n";
}

$iso->close();
exit 0;


