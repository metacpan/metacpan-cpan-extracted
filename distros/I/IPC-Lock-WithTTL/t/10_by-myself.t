# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;

use File::Temp;
use IPC::Lock::WithTTL;

my $myself = $$;
my $lockfile = File::Temp::tmpnam();

my $lock = IPC::Lock::WithTTL->new( file => $lockfile, ttl => 3 );
my($r, $locker);

# get lock
($r, $locker) = $lock->acquire;
ok $r, 'lock OK';
is $locker->{pid}, $myself, 'pid myself';
ok $locker->{expiration} > time(), 'expiration';

# not release lock

# previous time myself locked but didn't release lock
# not expire
($r, $locker) = $lock->acquire;
ok $r, 'lock OK (last locked proc is myself)';
is $locker->{pid}, $myself, 'pid myself'; # not 0
ok $locker->{expiration} > time(), 'expiration';

sleep 4;
# expired
($r, $locker) = $lock->acquire;
ok $r, 'lock OK (expired)';
is $locker->{pid}, $myself, 'pid myself';
ok $locker->{expiration} > time(), 'expiration';

done_testing;

unlink $lockfile;
