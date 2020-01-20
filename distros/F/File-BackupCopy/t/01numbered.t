# -*- perl -*-
use lib qw(t lib);
use strict;
use TestBackup;
use File::BackupCopy qw(backup_copy_numbered);
    
plan test => 9;

makefile('a');

my $name = backup_copy_numbered('a');
ok($name, 'a.~1~');
fileok('a', $name);

$name = backup_copy_numbered('a');
ok($name, 'a.~2~');
fileok('a', $name);
    
mkdir "subdir";
$name = backup_copy_numbered('a', dir => 'subdir');
ok($name, File::Spec->catfile('subdir','a.~1~'));
fileok('a', $name);

eval {
    backup_copy_numbered('a', dir => 'nonexisting');
};
ok(!!$@);

$name = backup_copy_numbered('a', dir => 'nonexisting', error => \my $err);
ok(!defined($name));
ok(defined($err) && $err ne '');
    
