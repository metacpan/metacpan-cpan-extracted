use lib 't/lib';
use IPC::Manager::Test::BlockInotify;

use Test2::V0;

use IPC::Manager::Util qw/USE_INOTIFY/;
ok(!USE_INOTIFY(), "Linux::Inotify2 is blocked");

use IPC::Manager::Test::BaseFS;
IPC::Manager::Test::BaseFS::run_tests();

done_testing;
