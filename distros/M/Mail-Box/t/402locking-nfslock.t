#!/usr/bin/env perl
#
# Test the locking methods.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Locker::NFS;
use Mail::Box;

use Test::More;
use File::Spec;

use Log::Report;

my $fakefolder = bless {MB_foldername=> 'this'}, 'Mail::Box';

BEGIN {
   if($windows)
   {   plan skip_all => "not available on MicroSoft Windows.";
       exit 0;
   }
}

my $lockfile  = File::Spec->catfile($workdir, 'lockfiletest');
unlink $lockfile;

my $locker = Mail::Box::Locker->new(
	method  => 'nfs',
	timeout => 1,
	wait    => 1,
	file    => $lockfile,
	folder  => $fakefolder,
);

ok($locker);
is($locker->name, 'NFS');

ok($locker->lock);
ok(-f $lockfile);
ok($locker->hasLock);

# Already got lock, so should return immediately.
ok try(sub { $locker->lock }, hide => 'ALL'), 'relock no problem';
my @e1 = $@->exceptions;
cmp_ok @e1, '==', 1;
like $e1[0]->message->toString, qr/already locked over NFS/;

$locker->unlock;
ok(not $locker->hasLock);

done_testing;
