# -*- perl -*-
use lib qw(t lib);
use strict;
use TestBackup;
use File::BackupCopy qw(backup_copy_simple);
    
plan test => 9;

makefile('a');

my $name = backup_copy_simple('a');
ok($name, 'a~');
fileok('a', $name);

$name = backup_copy_simple('a');
ok($name, 'a~');
fileok('a', $name);

mkdir "subdir";
$name = backup_copy_simple('a', dir => 'subdir');
ok($name, File::Spec->catfile('subdir','a~'));
fileok('a', $name);

eval {
    backup_copy_simple('a', dir => 'nonexisting');
};
ok(!!$@);

$name = backup_copy_simple('a', dir => 'nonexisting', error => \my $err);
ok(!defined($name));
ok(defined($err) && $err ne '');

# chmod 0, 'subdir';
# $name = backup_copy_simple('a', dir => 'subdir', error => \$err);
# ok(!defined($name));
# print "$err\n";

