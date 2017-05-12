#!/usr/bin/perl
use strict;
use Data::Dumper;
use File::Temp qw(tempdir tempfile);
my $td=tempdir("/tmp/funifs.td.XXXXXX");    # ,CLEANUP => 1);
my $mn=tempdir("/tmp/funifs.mn.XXXXXX");    # ,CLEANUP => 1);
my @cmd = ('perl','blib/sys/usr/sbin/funifs','/t',$mn,'-o','ro,noexec,nosuid,nodev,dirs='.$td.':/etc');
#funifs /y /tmp/y -o ro,noexec,nosuid,nodev,dirs=/tmp/z:/etc

use Test::More tests => 6;
ok( -d $td, 'tempdir(delta)' );
ok( -d $mn, 'tempdir(mount node)' );
ok( system(@cmd) == 0, 'mount.funifs' );
sleep 2;
ok( scalar(stat("$mn/group")), 'mounted' );
ok( system("fusermount","-u",$mn) == 0, 'umount' );
ok( system("rmdir",$td,$mn) == 0, 'rmdir /tmp/funifs.*' );

