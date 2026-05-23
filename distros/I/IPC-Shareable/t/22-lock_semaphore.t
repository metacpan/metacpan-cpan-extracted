use warnings;
use strict;

use Carp;
use IPC::Shareable qw(:lock);
use Test::More;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

my $t = tie my $sv, 'IPC::Shareable', {
    create => 1,
    key => 'data', 
    destroy => 1,
    serializer => 'storable',
};

my @none = qw(1 0 0);
my @excl = qw(1 0 1);
my @exnb = qw(1 0 1);
my @shar = qw(1 1 0);
my @shnb = qw(1 1 0);

for (0..2){
    is $t->sem->getval($_), $none[$_], "before excl lock, sem $_ set to $none[$_] ok";
}

$t->lock;
for (0..2){
    is $t->sem->getval($_), $excl[$_], "after excl lock, sem $_ set to $excl[$_] ok";
}

$t->unlock;
for (0..2){
    is $t->sem->getval($_), $none[$_], "after excl lock unlock, sem $_ set to $none[$_] ok";
}

$t->lock(LOCK_SH);
for (0..2){
    is $t->sem->getval($_), $shar[$_], "after shared lock, sem $_ set to $shar[$_] ok";
}

$t->unlock;
for (0..2){
    is $t->sem->getval($_), $none[$_], "after shared lock unlock, sem $_ set to $none[$_] ok";
}

$t->lock(LOCK_EX|LOCK_NB);
for (0..2){
    is $t->sem->getval($_), $exnb[$_], "after excl nb lock, sem $_ set to $exnb[$_] ok";
}

$t->unlock;
for (0..2){
    is $t->sem->getval($_), $none[$_], "after excl nb lock unlock, sem $_ set to $none[$_] ok";
}

$t->lock(LOCK_SH|LOCK_NB);
for (0..2){
    is $t->sem->getval($_), $shnb[$_], "after shared nb lock, sem $_ set to $shnb[$_] ok";
}

$t->unlock;
for (0..2){
    is $t->sem->getval($_), $none[$_], "after share nb lock unlock, sem $_ set to $none[$_] ok";
}

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();
