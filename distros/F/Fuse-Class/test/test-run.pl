#!/usr/local/bin/perl

#
# You can mount 'fuse28.pm' filesystem by running this script.
#

use strict;
use lib '..';
use lib '../blib/lib';
use lib '../blib/arch/auto';

use Cwd qw(abs_path);

use Fuse;
use test::fuse28;

my $mount_point = abs_path('mnt');

#
# make mount point if not exists
#

-d $mount_point || mkdir $mount_point, 0777;

print "fuse version: ", Fuse::fuse_version, "\n";
print "To umount, run:\n   fusermount -u $mount_point\nfrom other terminal.\n";
my $fs = new test::fuse28;
$fs->main(mountpoint => $mount_point,
	  debug=>1);
