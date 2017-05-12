use strict;
use warnings;

use Test::More;
use Global::MutexLock qw(mutex_create mutex_lock mutex_unlock mutex_destory);

ok my $id = mutex_create();
isnt $id, -1; 
is mutex_lock($id), 1, 'lock';
ok ! mutex_lock(undef), 'lock fail test';
is mutex_unlock($id), 1, 'unlock';
ok ! mutex_unlock(undef), 'unlock fail test';
is mutex_destory($id), 1, 'destory';
ok ! mutex_destory(undef), 'destory fail test';

done_testing;
