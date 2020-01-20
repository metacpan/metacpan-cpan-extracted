# -*- perl -*-
use lib qw(t lib);
use strict;
use TestBackup;
use File::BackupCopy;
    
plan test => 16;

makefile('a');

sub test_envar {
    my ($val, $exp) = @_;
    $ENV{VERSION_CONTROL} = $val;
    my $name = backup_copy('a');
    if (defined($exp)) {
	ok($name,$exp);
	fileok($name,'a');
    } else {
	ok(!defined($name));
    }
}

test_envar 'none';
test_envar 'off';
test_envar 'never', 'a~';
test_envar 'simple', 'a~';
test_envar 'numbered', 'a.~1~';
test_envar 't', 'a.~2~';
test_envar 'nil', 'a.~3~';
test_envar 'existing', 'a.~4~';
unlink qw(a.~1~ a.~2~ a.~3~ a.~4~);
test_envar 'existing', 'a~';

