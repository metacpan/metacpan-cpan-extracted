#!/usr/bin/perl -w
#  Copyright (C) 2006, 2008, 2017 Rocky Bernstein <rocky@cpan.org>
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
use Device::Cdio::ISO9660::IFS;
use File::Spec;

sub tm2str($) {
    my $tm = shift;
    return sprintf("%s %02d %s %s:%s:%s",
		   qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec")[$tm->{mon}-1],
		   $tm->{mday}, $tm->{year},
	           $tm->{hour}, $tm->{min}, $tm->{sec});
}

# The default ISO 9660 image if none given
my $ISO9660_IMAGE_PATH="../data";
my $ISO9660_IMAGE=File::Spec->catfile($ISO9660_IMAGE_PATH, "copying.iso");

my $iso_image_fname = $ISO9660_IMAGE;
$iso_image_fname = $ARGV[0] if @ARGV >= 1;

my $iso = Device::Cdio::ISO9660::IFS->new(-source=>$iso_image_fname);

if (!defined($iso)) {
    printf "Sorry, couldn't open %s as an ISO-9660 image.\n", $iso_image_fname;
    exit 1;
}

my $path = '/';
my @file_stats = $iso->readdir($path);

my $id = $iso->get_application_id();
printf "Application ID: %s\n", $id if defined($id);

$id = $iso->get_preparer_id();
printf "Preparer ID: %s\n", $id if defined($id);

$id = $iso->get_publisher_id();
printf "Publisher ID: %s\n", $id if defined($id);

$id = $iso->get_system_id();
printf "System ID: %s\n", $id if defined($id);

$id = $iso->get_volume_id();
printf "Volume ID: %s\n", $id if defined($id);

$id = $iso->get_volumeset_id();
printf "Volumeset ID: %s\n", $id if defined($id);

foreach my $href (@file_stats) {
    printf "%s [LSN %6d] %8d %s %s%s\n",
    $href->{is_dir} ? "d" : "-",
    $href->{LSN}, $href->{size},
    tm2str($href->{tm}),
    $path,
    Device::Cdio::ISO9660::name_translate($href->{filename});
}

$iso->close();
exit 0;
