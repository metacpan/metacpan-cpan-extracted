#!/usr/bin/env perl

#
# Test the locking methods.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Locker::Flock;
use Mail::Box;

use Test::More;
use File::Spec;

BEGIN
{   if($windows)
    {   plan skip_all => "not available on MicroSoft Windows";
        exit 0;
    }

    plan tests => 7;
}

my $fakefolder = bless {MB_foldername=> 'this'}, 'Mail::Box';
my $lockfile   = File::Spec->catfile($workdir, 'lockfiletest');

unlink $lockfile;
open my $out, '>', $lockfile;   # create lockfile

my $locker = Mail::Box::Locker->new
  ( method  => 'FLOCK'
  , timeout => 1
  , wait    => 1
  , file    => $lockfile
  , folder  => $fakefolder
  );

ok($locker,                                       'create locker');
is($locker->name, 'FLOCK',                        'lock name');

ok($locker->lock,                                 'do lock');
ok(-f $lockfile,                                  'locked file exists');
ok($locker->hasLock,                              'lock received');

# Already got lock, so should return immediately.
my $warn = '';
{  $SIG{__WARN__} = sub {$warn = "@_"};
   $locker->lock;
}
ok($warn =~ m/already flocked/,                   'relock no problem');

$locker->unlock;
ok(! $locker->hasLock,                            'unlocked');

$out->close;
unlink $lockfile;
