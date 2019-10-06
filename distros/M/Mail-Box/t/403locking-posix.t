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

BEGIN
{   if($windows)
    {   plan skip_all => "not available on MicroSoft Windows.";
        exit 0;
    }

    plan tests => 7;
}

my $fakefolder = bless {MB_foldername=> 'this'}, 'Mail::Box';

my $lockfile  = File::Spec->catfile($workdir, 'lockfiletest');
unlink $lockfile;
open OUT, '>', $lockfile;
close OUT;

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
my $warn = '';
{  $SIG{__WARN__} = sub {$warn = "@_"};
   $locker->lock;
}
ok($warn =~ m/already lockf/,                   'relock no problem');

$locker->unlock;
ok(not $locker->hasLock);

close OUT;
unlink $lockfile;
