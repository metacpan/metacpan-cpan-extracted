#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp ();

use GID;

my $dir = tempdir;

isa_ok($dir,'GID::Dir','Getting a GID::Dir from tempdir');

my $subdir = $dir->mkdir("bla");

ok(-d $subdir,'Subdirectory in tempdir is made');

my $tempfile = $subdir->tempfile;
ok($subdir->subsumes($tempfile),'New tempfile is in subdirectory of tempdir');
isa_ok($tempfile,'GID::File','Tempfile is a GID::File');
my $other_tempfile = $subdir->tempfile;
ok($subdir->subsumes($other_tempfile),'Other new tempfile is in subdirectory of tempdir');
my $some_subdir = $subdir->mkdir('some');

my $dir_test_some_subdir = $subdir->dir('some');
isa_ok($dir_test_some_subdir,'GID::Dir','dir function of GID::Dir works');

my $entities_count = 0;
$subdir->entities(sub {
	$entities_count += 1;
});
is($entities_count,3,'Callback for entities called proper often');

my $files_count = 0;
$subdir->files(sub {
	$files_count += 1;
});
is($files_count,2,'Callback for files called proper often');

my $dirs_count = 0;
$subdir->dirs(sub {
	$dirs_count += 1;
});
is($dirs_count,1,'Callback for dirs called proper often');

$subdir->rm;
is($subdir->rm,0,'Subdir rm try gives back 0');
ok(-d $subdir,'And subdir is still there!');

is($subdir->rmrf,4,'Subdir rmrf try gives back 0');
ok(!-d $subdir,'And subdir is gone!');

done_testing;
