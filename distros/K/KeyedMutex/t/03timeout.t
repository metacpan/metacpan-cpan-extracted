use strict;
use warnings;

use Test::More tests => 8;

use constant SOCKPATH => 't/keyedmutexd.sock';

BEGIN { use_ok('KeyedMutex'); }

my($km, $server_pid);

# fire up the server
if ($server_pid = fork) {
    die 'fork failed' if $server_pid == -1;
} else {
    close STDOUT;
    open STDOUT, '>', '/dev/null' or die 'failed to reopen stdout';
    exec 'keyedmutexd/keyedmutexd -t 2 -f -s ' . SOCKPATH;
    die 'failed to exec keyedmutexd';
}
sleep 5;

# establish connection
eval {
    $km = KeyedMutex->new({
        sock => SOCKPATH,
    });
};
ok($km, 'instantiation');

# lock tests
is($km->lock('test'), 1, 'acquire lock');
ok($km->release, 'release');

# lock timeout tests
is($km->lock('test'), 1, 'acquire lock');
sleep 5;
ok($km->release, 'release');

# lock once more after timeout, should suceed using auto_reconnect feature
is($km->lock('test'), 1, 'acquire lock');
ok($km->release, 'release');

# kill server
kill 15, $server_pid;
