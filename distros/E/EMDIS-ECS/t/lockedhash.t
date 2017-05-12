#!/usr/bin/perl -w
#
# Copyright (C) 2002-2016 National Marrow Donor Program. All rights reserved.

use strict;
use Fcntl qw(:flock);
use File::Spec::Functions qw(tmpdir);
use Test;
use vars qw($childpid $data $datafile @delfiles @keys $lockfile $tbl $tmpdir);
use FindBin;
use lib "$FindBin::Bin";
require 'setup';

# print test plan before loading modules
BEGIN { plan(tests => 62); }
use EMDIS::ECS::LockedHash;

# [1] Was module successfully loaded?
ok(1);

# [2] Is module version consistent?
require EMDIS::ECS;
ok($EMDIS::ECS::VERSION == $EMDIS::ECS::LockedHash::VERSION);

# redirect STDERR to STDOUT (suppress STDERR output during "make test")
open STDERR, ">&STDOUT" or die "Unable to dup STDOUT: $!\n";
select STDERR; $| = 1;   # make unbuffered
select STDOUT; $| = 1;   # make unbuffered

# define "testhash" filenames, remove existing "t/tmp/testhash*" files
$datafile = catfile($tmpdir, 'testhash.dat');
$lockfile = catfile($tmpdir, 'testhash.lock');
# the following may be needed for lockfile to avoid NFS
#$lockfile = catfile(tmpdir, 'emdis_testhash.lock');
opendir TMPDIR, $tmpdir
    or die "unable to open directory: $tmpdir";
@delfiles = map { catfile($tmpdir, $_); } grep /^testhash/, readdir TMPDIR;
closedir TMPDIR;
for my $filename (@delfiles) {
    unlink $filename
        or die "unable to remove file: $filename";
}

# [3..4] constructor usage errors
$tbl = new EMDIS::ECS::LockedHash();
ok(not defined $tbl);
$tbl = new EMDIS::ECS::LockedHash($datafile);
ok(not defined $tbl);

# [5..11] create new LockedHash
$tbl = new EMDIS::ECS::LockedHash($datafile, $lockfile);
ok(defined $tbl);
ok($tbl->{dbfile} eq $datafile);
ok($tbl->{lockfile} eq $lockfile);
ok($tbl->{lock_timeout} == 10);
ok(not $tbl->ERROR);
ok(not $tbl->LOCK);
ok(not $tbl->TIED);

# [12..19] _lock(), _unlock()
ok($tbl->LOCK == 0);
ok($tbl->_lock());
ok($tbl->LOCK == LOCK_EX);
$childpid = fork();
if(not $childpid) {
    # child process is needed to test locking
    my $tbl2 = new EMDIS::ECS::LockedHash($datafile, $lockfile, 2);
    exit(1) unless defined $tbl2;
    exit(1) unless $tbl2->{lock_timeout} == 2;
    exit(1) if $tbl2->_lock();
    exit(0);
}
waitpid($childpid, 0);
ok($? == 0);
$tbl->_unlock();
ok($tbl->LOCK == 0);
ok($tbl->_lock(LOCK_SH));
ok($tbl->LOCK == LOCK_SH);
$tbl->_unlock();
ok($tbl->LOCK == 0);

# [20..26] _tie, _untie
ok($tbl->_tie());
ok($tbl->TIED);
ok('HASH' eq ref $tbl->{hash});
ok('SDBM_File' eq ref $tbl->{db_obj});
$tbl->_untie();
ok(not $tbl->TIED);
ok(not exists $tbl->{hash});
ok(not exists $tbl->{db_obj});

# [27..32] lock, unlock
ok($tbl->LOCK == 0);
ok($tbl->lock);
ok($tbl->LOCK == LOCK_EX);
ok($tbl->TIED);
$tbl->unlock();
ok($tbl->LOCK == 0);
ok(not $tbl->TIED);

# [33..37] write
ok(not $tbl->write('key', 'value'));
ok($tbl->ERROR =~ /requires exclusive lock/);
ok($tbl->lock());
ok($tbl->write('key1', 'value'));
ok($tbl->write('key2', { a => 'b', c => 'd', e => 'f' }));
$tbl->unlock();

# [39..47] read
ok(not $tbl->read('key1'));
ok($tbl->ERROR =~ /requires shared or exclusive lock/);
ok($tbl->lock());
$data = $tbl->read('key1');  # retrieve scalar
ok($data eq 'value');
$data = $tbl->read('key2');  # retrieve hash
ok('HASH' eq ref $data);
ok($data->{a} eq 'b');
ok($data->{c} eq 'd');
ok($data->{e} eq 'f');
ok(not defined $data->{g});
$data = $tbl->read('key3');  # retrieve non-existent
ok(not defined $data);
$tbl->unlock();

# [48..52] delete
ok(not $tbl->delete('key1'));
ok($tbl->ERROR =~ /requires exclusive lock/);
ok($tbl->lock());
ok($tbl->delete('key1'));
ok(not defined $tbl->read('key1'));
$tbl->unlock();

# [53..57] keys
ok(not $tbl->keys());
ok($tbl->ERROR =~ /requires shared or exclusive lock/);
ok($tbl->lock);
@keys = $tbl->keys();
ok($#keys == 0);
ok($keys[0] eq 'key2');
$tbl->unlock();

# [58..62] undef
ok(not $tbl->undef());
ok($tbl->ERROR =~ /requires exclusive lock/);
ok($tbl->lock);
ok($tbl->undef());
@keys = $tbl->keys();
ok($#keys == -1);
$tbl->unlock();

unlink $lockfile;
