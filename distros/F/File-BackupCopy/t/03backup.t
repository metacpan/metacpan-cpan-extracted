# -*- perl -*-
use lib qw(t lib);
use strict;
use TestBackup;
use File::BackupCopy;
    
plan test => 24;

makefile('a');

my $name = backup_copy('a',BACKUP_NONE);
ok(!defined($name));

$name = backup_copy('a',BACKUP_SIMPLE);
ok($name, 'a~');
fileok('a', $name);

$name = backup_copy('a',BACKUP_AUTO);
ok($name, 'a~');
fileok('a', $name);

$name = backup_copy('a',BACKUP_NUMBERED);
ok($name, 'a.~1~');
fileok('a', $name);

$name = backup_copy('a',BACKUP_AUTO);
ok($name, 'a.~2~');
fileok('a', $name);

$name = backup_copy('a');
ok($name, 'a.~3~');
fileok('a', $name);

$name = backup_copy('a', type => BACKUP_SIMPLE);
ok($name, 'a~');
fileok('a', $name);

mkdir "subdir";
$name = backup_copy('a', dir => 'subdir', type => BACKUP_SIMPLE);
ok($name, File::Spec->catfile('subdir','a~'));
fileok('a', $name);

$name = backup_copy('a', dir => 'subdir', type => BACKUP_AUTO);
ok($name, File::Spec->catfile('subdir','a~'));
fileok('a', $name);

$name = backup_copy('a', dir => 'subdir', type => BACKUP_NUMBERED);
ok($name, File::Spec->catfile('subdir','a.~1~'));
fileok('a', $name);

$name = backup_copy('a', dir => 'subdir', type => BACKUP_AUTO);
ok($name, File::Spec->catfile('subdir','a.~2~'));
fileok('a', $name);

eval {
    backup_copy('a', dir => 'nonexisting');
};
ok(!!$@);

$name = backup_copy('a', dir => 'nonexisting', error => \my $err);
ok(!defined($name));
ok(defined($err) && $err ne '');

