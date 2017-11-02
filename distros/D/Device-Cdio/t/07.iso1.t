#!/usr/bin/env perl
# Test of some ISO9660::IFS routines
# This is similar to example/iso1.pl

use strict;
use warnings;
use Config;

BEGIN {
    chdir 't' if -d 't';
    use lib '../lib';
    eval "use blib";  # if we fail keep going - maybe we have installed Cdio
}

use Device::Cdio;
use Device::Cdio::Device;
use Device::Cdio::ISO9660;
use Device::Cdio::ISO9660::IFS;
use File::Spec;

use Test::More tests => 6;
note 'Test ISO9660::IFS routines';

# Use Canonic timezone in date testing
$ENV{'TZ'} = 'UTC';

# The test ISO 9660 image
my $ISO9660_IMAGE_PATH="../data";
my $iso_image_fname=File::Spec->catfile($ISO9660_IMAGE_PATH, "copying.iso");

my $iso = Device::Cdio::ISO9660::IFS->new(-source=>$iso_image_fname);

ok(defined($iso), "Open ISO 9660 image $iso_image_fname") ;

ok($iso->get_application_id() eq
"MKISOFS ISO 9660/HFS FILESYSTEM BUILDER & CDRECORD CD-R/DVD CREATOR (C) 1993 E.YOUNGDALE (C) 1997 J.PEARSON/J.SCHILLING",
"get_application_id()");

ok($iso->get_system_id() eq "LINUX", "get_system_id() eq 'LINUX'");
ok($iso->get_volume_id() eq "CDROM", "get_volume_id() eq 'CDROM'");

my $path = '/';
my @file_stats = $iso->readdir($path);


my @okay_stats = (
    { LSN=>23, 'filename'=>'.', is_dir=>1, sec_size=>1, size=>2048,
      tm => {
          hour  => 21,
	  isdst =>  0,
	  mday  =>  5,
	  min   => 50,
	  mon   =>  1,
	  sec   => 19,
	  wday  =>  4,
	  yday  =>  4,
	  year  => 2006,
        },
    },
    { LSN=>23, 'filename'=>'..', is_dir=>1, sec_size=>1, size=>2048,
      tm => {
          hour  => 21,
	  isdst =>  0,
	  mday  =>  5,
	  min   => 50,
	  mon   =>  1,
	  sec   => 19,
	  wday  =>  4,
	  yday  =>  4,
	  year  => 2006,
      },
    },
    { LSN=>24, 'filename'=>'COPYING.;1', is_dir=>'', sec_size=>9, size=>18002,
      tm => {
          hour  => 21,
	  isdst =>  0,
	  mday  =>  5,
	  min   => 46,
	  mon   =>  1,
	  sec   => 30,
	  wday  =>  4,
	  yday  =>  4,
	  year  => 2006,
     } },
    );

is_deeply(\@file_stats, \@okay_stats, 'ISO 9660 file stats');

my $copy_stat = $iso->find_lsn(24);
is_deeply($copy_stat, $okay_stats[2], "Finding stat for root (24)");

$iso->close();
