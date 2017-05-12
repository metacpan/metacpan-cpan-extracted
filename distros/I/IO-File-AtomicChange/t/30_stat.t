# -*- mode: cperl -*-
use strict;
use warnings;
use t::Utils;

use Test::More;
plan tests => 5;

use FindBin;
use IO::File::AtomicChange;

my $basedir     = $FindBin::Bin; # t/
my $target_file = "$basedir/file/30_stat";
my $basename    = substr($target_file, rindex($target_file, "/")+1);
my $backup_dir  = "$basedir/bak/";
my(@data, $f, $testee);
my(@backup);
my(@stat, @stat_old);
END { unlink $target_file; cleanup_backup($backup_dir, $basename); }

### wrote for prepare file
@data = map $_."\n", qw(ichi ni);
unlink $target_file if -f $target_file;
cleanup_backup($backup_dir, $basename);
$testee = write_and_read([$target_file, "w"], \@data);
is($testee, join("",@data), "create truncate write");

###
chmod 0765, $target_file;
@stat_old = stat_mode_owner($target_file);

@data = map $_."\n", qw(san shi);
$testee = write_and_read([$target_file, "w"], \@data);
is($testee, join("",@data), "create truncate write");

### preserve mode and uid, gid between old file and new file.
@stat = stat_mode_owner($target_file);
is_deeply(\@stat, \@stat_old, "mode and uid,gid preserved?");

### preserve mode and uid, gid and mtime between backuped file and file before write.
###
my $mtime = time - 5;
utime $mtime, $mtime, $target_file;
@stat_old = stat_mode_owner($target_file);
push @stat_old, stat_time($target_file);
@data = map $_."\n", qw(go roku);
$testee = write_and_read([$target_file, "w", {backup_dir=>$backup_dir}], \@data);
is($testee, join("",@data), "create truncate write");
@backup = list_backup($backup_dir, $basename);
@stat = stat_mode_owner($backup[0]->stringify);
push @stat, stat_time($backup[0]->stringify);
is_deeply(\@stat, \@stat_old, "mtime preserved?");
