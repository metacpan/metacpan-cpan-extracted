#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 11;
use lib 'lib';
require_ok('File::Lock::ParentLock');

my $locker= File::Lock::ParentLock->new();
ok (!$locker->is_locked_by_us);
ok (!$locker->is_locked_by_others);
ok ($locker->can_lock);
my $status=$locker->lock;
#print "# status=$status\n";
ok ($status==1);
ok ($locker->is_locked_by_us);
ok (!$locker->is_locked_by_others);
ok ($locker->can_lock);
$locker->unlock;
ok (!$locker->is_locked_by_us);
ok (!$locker->is_locked_by_others);
ok ($locker->can_lock);
