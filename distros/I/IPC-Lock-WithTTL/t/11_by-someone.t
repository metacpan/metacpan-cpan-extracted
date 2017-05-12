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

my $child;
if ($child = fork) {
    wait;
} else {
    $lock->acquire;
    # not release lock
    exit;
}

# previous time another process locked but didn't release lock
# not expired
($r, $locker) = $lock->acquire;
ok !$r, 'lock NG (not expired)';
is $locker->{pid}, $child, 'pid another(child)';
ok $locker->{expiration} > time(), 'expiration';

sleep 4;
# expired
($r, $locker) = $lock->acquire;
ok $r, 'lock OK (expired)';
is $locker->{pid}, $myself, 'pid myself';
ok $locker->{expiration} > time(), 'expiration';

done_testing;

unlink $lockfile;
