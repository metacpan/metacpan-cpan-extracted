#!/usr/bin/env perl
#
# Test the locking methods.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Locker::DotLock;
use Mail::Box;

use Test::More;
use File::Spec;

use Log::Report;

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
ok try(sub { $locker->lock }, hide => 'ALL'), 'second attempt';
my @e1 = $@->exceptions;
cmp_ok @e1, '==', 1;
like $e1[0]->message->toString, qr/already locked with file/;

$locker->unlock;
ok(! $locker->hasLock, 'released lock');

done_testing;
