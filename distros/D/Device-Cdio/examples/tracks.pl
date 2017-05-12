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

### Program to show CD information

BEGIN {
    chdir 'example' if -d 'example';
    use lib '../lib';
    eval "use blib";  # if we fail keep going - maybe we have installed Cdio
}

use Device::Cdio;
use Device::Cdio::Device;

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
        
my $t = $d->get_first_track();
if (!defined($t)) {
    print "Problem getting first track.\n";
    exit(2);
}
my $first_track = $t->{track};
my $num_tracks  = $d->get_num_tracks();
my $last_track  = $first_track+$num_tracks-1;

my ($drc, $last_session) = $d->get_last_session();

if ($drc == $perlcdio::DRIVER_OP_SUCCESS) {
    printf("CD-ROM %s has %d track(s) and %d session(s).\n",
	   $drive_name, $d->get_num_tracks(), $last_session);
} elsif ($drc == $perlcdio::DRIVER_OP_UNSUPPORTED) {
    printf("CD-ROM %s has %d track(s).\n", 
	   $drive_name, $d->get_num_tracks());
} else {
    print "Error in getting last session\n";
}

printf("Track format is %s.\n", $d->get_disc_mode());
my $mcn = $d->get_mcn();
printf "Media Catalog Number: %s\n", $mcn if $mcn;
    
printf "%3s: %-6s  %-6s   %s\n", "#", "LSN", "MSF", "Format";
for (my $i=$first_track; $i <= $last_track; $i++) {
    my $t = $d->Device::Cdio::Device::get_track($i);
    printf("%3d: %06lu  %-6s %s\n", $t->{track}, $t->get_lsn(), 
	   $t->get_msf(), $t->get_format())
	if defined($t);
}

printf("%3X: %06lu  leadout\n", 
	$perlcdio::CDROM_LEADOUT_TRACK, $d->get_disc_last_lsn());
$d->close();
