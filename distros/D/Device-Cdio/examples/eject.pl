#!/usr/bin/perl -w
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

# Program to Eject and close CD-ROM drive

BEGIN {
    chdir 'example' if -d 'example';
    use lib '../lib';
    eval "use blib";  # if we fail keep going - maybe we have installed Cdio
}

use Device::Cdio;
use Device::Cdio::Device;

my $drive_name;
my $d;
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

print "Ejecting CD in drive $drive_name\n";
my $drc = $d->eject_media();
if ($drc == $perlcdio::DRIVER_OP_SUCCESS) {
    my ($drc, $driver_id) = Device::Cdio::close_tray($drive_name);
    if ($drc == $perlcdio::DRIVER_OP_SUCCESS) {
	print "Closed tray of CD-ROM drive $drive_name\n";
    } else {
	print "Closing tray of CD-ROM drive $drive_name failed\n";
    }
} elsif ($drc= $perlcdio::DRIVER_OP_UNSUPPORTED) {
    print "Eject not supported for $drive_name\n";
} else {
    print "Eject of CD-ROM drive $drive_name failed\n";
}

    

  
