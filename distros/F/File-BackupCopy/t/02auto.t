# -*- perl -*-
use lib qw(t lib);
use strict;
use TestBackup;
use File::BackupCopy qw(backup_copy_numbered backup_copy_auto);
    
plan test => 16;

makefile('a');

my $name = backup_copy_auto('a');
ok($name, 'a~');
fileok('a', $name);

$name = backup_copy_numbered('a');
ok($name, 'a.~1~');
fileok('a', $name);
    
$name = backup_copy_auto('a');
ok($name, 'a.~2~');
fileok('a', $name);

mkdir "subdir";
$name = backup_copy_auto('a', dir => 'subdir');
ok($name, File::Spec->catfile('subdir','a~'));
fileok('a', $name);

$name = backup_copy_auto('a', dir => 'subdir');
ok($name, File::Spec->catfile('subdir','a~'));
fileok('a', $name);

ok(open(FH, '>', File::Spec->catfile('subdir','a.~1~')));
$name = backup_copy_auto('a', dir => 'subdir');
ok($name, File::Spec->catfile('subdir','a.~2~'));
fileok('a', $name);

eval {
    backup_copy_auto('a', dir => 'nonexisting');
};
ok(!!$@);

$name = backup_copy_auto('a', dir => 'nonexisting', error => \my $err);
ok(!defined($name));
ok(defined($err) && $err ne '');
