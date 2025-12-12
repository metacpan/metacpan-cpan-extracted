#!/usr/bin/env perl
#
# Test the locking methods.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Locker::POSIX;
use Mail::Box;

use Test::More;
use File::Spec;

use Log::Report;

BEGIN
{   if($windows)
    {   plan skip_all => "not available on MicroSoft Windows.";
        exit 0;
    }
}

my $fakefolder = bless {MB_foldername=> 'this'}, 'Mail::Box';

my $lockfile  = File::Spec->catfile($workdir, 'lockfiletest');
unlink $lockfile;

open my $out, '>', $lockfile;
$out->close;

my $locker = Mail::Box::Locker->new
 ( method  => 'POSIX'
 , timeout => 1
 , wait    => 1
 , file    => $lockfile
 , folder  => $fakefolder
 );

ok(defined $locker);
is($locker->name, 'POSIX');

ok($locker->lock);
ok(-f $lockfile);
ok($locker->hasLock);

# Already got lock, so should return immediately.
ok try(sub { $locker->lock }, hide => 'ALL'), 'relock no problem';
my @e1 = $@->exceptions;
cmp_ok @e1, '==', 1;
like $e1[0]->message->toString, qr/already lockf/;

$locker->unlock;
ok(not $locker->hasLock);

unlink $lockfile;

done_testing;
