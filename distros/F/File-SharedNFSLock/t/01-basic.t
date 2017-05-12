#! perl

use strict;
use warnings;
use Test::More;

use File::SharedNFSLock;

my $some_file = 'some_file_on_nfs';
my $lock_file = 'some_file_on_nfs.lock';


# Basic tests

ok my $flock = File::SharedNFSLock->new(
    file => $some_file,
);

isa_ok $flock, 'File::SharedNFSLock';

ok not $flock->is_locked;
ok not $flock->got_lock;
ok not $flock->locked;
ok not -f $lock_file;

ok $flock->lock;

ok $flock->is_locked;
ok $flock->got_lock;
ok -f $lock_file;

ok $flock->unlock;

ok not $flock->is_locked;
ok not $flock->locked;
ok not -f $lock_file;

ok $flock->wait;

write_lock_file($lock_file);
ok $flock->is_locked;
rm_lock_file($lock_file);


sub write_lock_file {
  my ($file) = @_;
  open my $out, '>', $file or die "Error: Could not write file $file\n$!\n";
  close $out;
}

sub rm_lock_file {
  my ($file) = @_;
  unlink $file;
}


done_testing();
