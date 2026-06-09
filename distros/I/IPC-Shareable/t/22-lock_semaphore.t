use warnings;
use strict;

use Carp;
use IPC::Shareable qw(:lock);
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process unique_glue);


my $t = tie my $sv, 'IPC::Shareable', {
    create => 1,
    key => unique_glue('data'), 
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

assert_clean_process();

done_testing();
