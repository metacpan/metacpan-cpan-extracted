# -*- mode: cperl -*-
use strict;
use warnings;
use t::Utils;

use Test::More;
plan tests => 6;

use FindBin;
use IO::File::AtomicChange;

my $basedir     = $FindBin::Bin; # t/
my $target_file = "$basedir/file/20_backup";
my $basename    = substr($target_file, rindex($target_file, "/")+1);
my $backup_dir  = "$basedir/bak/";
my(@data, $f, $testee);
my(@wrote, @backup, @backup2, $data_backuped);
END { unlink $target_file; cleanup_backup($backup_dir, $basename); }

### wrote / read after write
@data = map $_."\n", qw(ichi ni);
unlink $target_file if -f $target_file;
cleanup_backup($backup_dir, $basename);

$testee = write_and_read([$target_file, "w", {backup_dir=>$backup_dir}], \@data);
is($testee, join("",@data), "create truncate write");

### still no backup file
@backup = list_backup($backup_dir, $basename);
is(scalar(@backup), 0, "no need backup");

### one backup file after write to existing file
@wrote = ();
@data = map $_."\n", qw(san shi);
$testee = write_and_read([$target_file, "w", {backup_dir=>$backup_dir}], \@data);
push @wrote, @data;
@backup = list_backup($backup_dir, $basename);
is(scalar(@backup), 1, "do backup (1)");

###
$data_backuped = slurp($target_file);
@data = map $_."\n", qw(go roku);
$testee = write_and_read([$target_file, "a", {backup_dir=>$backup_dir}], \@data);
push @wrote, @data;
@backup2 = list_backup($backup_dir, $basename);
is(scalar(@backup2), 2, "do backup (2)");
my %old_backup = map { $_->stringify => 1 } @backup;
@backup2 = grep { ! $old_backup{ $_->stringify } } @backup2;

###
###
is($testee, join("",@wrote), "new data");
$testee = $backup2[0]->slurp;
is($testee, $data_backuped, "backuped data");
