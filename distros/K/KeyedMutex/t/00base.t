use strict;
use warnings;

use Test::More tests => 13;

use constant SOCKPATH => 't/keyedmutexd.sock';

BEGIN { use_ok('KeyedMutex'); }

my($km, $km2, $server_pid);

unlink SOCKPATH;

eval {
    $km = KeyedMutex->new({
        sock => SOCKPATH,
    });
};
ok(! $km, 'connect to a nonexistent unix domain socket, should fail');

# fire up the server
if ($server_pid = fork) {
    die 'fork failed' if $server_pid == -1;
} else {
    close STDOUT;
    open STDOUT, '>', '/dev/null' or die 'failed to reopen stdout';
    exec 'keyedmutexd/keyedmutexd -f -s ' . SOCKPATH;
    die 'failed to exec keyedmutexd';
}
sleep 5;

# establish two connections
eval {
    $km = KeyedMutex->new({
        sock => SOCKPATH,
    });
};
ok($km, 'instantiation');
eval {
    $km2 = KeyedMutex->new({
        sock => SOCKPATH,
    });
};
ok($km2, 'instantiate another');

# lock tests
ok(! $km->locked, 'not holding a lock');
is($km->lock('test'), 1, 'acquire lock');
ok($km->locked, 'holding a lock');
ok($km->release, 'release');
ok(! $km->locked, 'not holding a lock');
is($km->lock('test'), 1, 'acquire once more');
ok($km->locked, 'holding a lock again');
ok($km->release, 'release');
ok(! $km->locked, 'not holding a lock');

# kill server
kill 15, $server_pid;
