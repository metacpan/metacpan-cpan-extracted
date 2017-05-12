use strict;
use warnings;

use Test::More;
use Test::LeakTrace;
use Global::MutexLock qw( 
    mutex_create
    mutex_lock
    mutex_unlock
    mutex_destory
);

no_leaks_ok {
    my $id = mutex_create();
    mutex_lock($id);
    mutex_unlock($id);
    mutex_destory($id);
};

no_leaks_ok {
    mutex_lock(undef);
    mutex_unlock(undef);
    mutex_destory(undef);
};

no_leaks_ok {
    mutex_lock(-1);
    mutex_unlock(-1);
    mutex_destory(-1);
};

done_testing;
