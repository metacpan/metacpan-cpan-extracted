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

# Simple program to show using Device::Cdio::ISO9660 to extract a file
# from an CD image.
#
# If a single argument is given, it is used as the ISO 9660 image to
# use in the extraction. Otherwise a compiled in default ISO 9660
# image name (that comes with the libcdio distribution) will be used.

use strict;

BEGIN {
    chdir 'example' if -d 'example';
    use lib '../lib';
    eval "use blib";  # if we fail keep going - maybe we have installed Cdio
}

use POSIX;
use IO::Handle;
use Device::Cdio;
use Device::Cdio::Device;
use Device::Cdio::ISO9660;
use Device::Cdio::ISO9660::FS;
use Device::Cdio::Device;
use File::Spec;

# The default CD image if none given
my $cd_image_path="../data";
my $cd_image_fname=File::Spec->catfile($cd_image_path, "isofs-m1.cue");

# File to extract if none given.
my $iso9660_path="/";
my $local_filename="COPYING";

if (@ARGV >= 1) {
    $cd_image_fname = $ARGV[0];
    if (@ARGV >= 2) {
	$local_filename = $ARGV[1];
	if (@ARGV >= 3) {
	    print "
usage: $0 [CD-ROM-or-image [filename]]
Extracts filename from CD-ROM-or-image.
";
	    exit 1;
	}
    }
}
my $cd = Device::Cdio::ISO9660::FS->new(-source=>$cd_image_fname);
  
if (!defined($cd)) {
    printf "Sorry, couldn't open %s as a CD image\n", $cd_image_fname;
    exit 1;
}

my $statbuf = $cd->stat (File::Spec->catfile($iso9660_path, $local_filename));

if (!defined($statbuf))
{
    printf "Could not get ISO-9660 file information for file %s in %s\n",
	    $local_filename, $cd_image_fname;
    $cd->close();
    exit 2;
}

open OUTPUT, ">$local_filename" or
    die "Can't open $local_filename for writing: $!";

binmode OUTPUT;

# Copy the blocks from the ISO-9660 filesystem to the local filesystem. 
my $blocks = POSIX::ceil($statbuf->{size} / $perlcdio::ISO_BLOCKSIZE);
for (my $i = 0; $i < $blocks; $i++) {
    my $lsn = $statbuf->{LSN} + $i;
    my $buf = $cd->read_data_blocks ($lsn);

    if (!defined($buf)) {
	printf "Error reading ISO 9660 file %s at LSN %d\n",
	$local_filename, $lsn;
	exit 4;
    }
    
    syswrite OUTPUT, $buf, $perlcdio::ISO_BLOCKSIZE;
}

OUTPUT->autoflush(1);

# Make sure the file size has the exact same byte size. Without the
# truncate below, the file will a multiple of ISO_BLOCKSIZE.

truncate OUTPUT, $statbuf->{size};

printf "Extraction of file '%s' from %s successful.\n", 
    $local_filename,  $cd_image_fname;

close OUTPUT;
$cd->close();
exit 0;
