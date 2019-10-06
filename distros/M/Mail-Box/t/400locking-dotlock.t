#!/usr/bin/env perl
#
# Test the locking methods.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Locker::DotLock;
use Mail::Box;

use Test::More tests => 7;
use File::Spec;

my $fakefolder = bless {MB_foldername=> 'this'}, 'Mail::Box';
my $lockfile   = File::Spec->catfile($workdir, 'lockfiletest');

unlink $lockfile;

my $locker = Mail::Box::Locker->new
 ( method  => 'DotLock'
 , timeout => 1
 , wait    => 1
 , file    => $lockfile
 , folder  => $fakefolder
 );

ok($locker);
is($locker->name, 'DOTLOCK', 'locker name');

ok($locker->lock,    'can lock');
ok(-f $lockfile,     'lockfile found');
ok($locker->hasLock, 'locked status');

# Already got lock, so should return immediately.
my $warn = '';
{  $SIG{__WARN__} = sub {$warn = "@_"};
   $locker->lock;
}
ok($warn =~ m/already locked/, 'second attempt');

$locker->unlock;
ok(! $locker->hasLock, 'released lock');
