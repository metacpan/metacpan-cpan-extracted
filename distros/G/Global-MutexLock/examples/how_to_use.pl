#! /usr/bin/env perl
use strict;
use warnings;

# 0. use Global::MutexLock;
use Global::MutexLock qw(mutex_create mutex_destory mutex_lock mutex_unlock);

# 1. create a new global mutex id
# tips: you can create an id, and use it in different crons or apps
my $mutex_id = mutex_create();

# 2. take a lock
unless (mutex_lock($mutex_id)) {
    warn "lock error";
}

# 3. do something...
# ...

# 4. release lock
unless (mutex_unlock($mutex_id)) {
    warn "release lock error";
}

# 5. destory mutex lock id
# you must do it. otherwise the IPC id will be leaved in system.
# or you can rm it by `ipcrm -m IPCID`
# you can find IPCID by `ipcs`
mutex_destory($mutex_id);
