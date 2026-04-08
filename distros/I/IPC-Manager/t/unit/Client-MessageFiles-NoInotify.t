use lib 't/lib';
use IPC::Manager::Test::BlockInotify;

use Test2::V0;

use IPC::Manager::Util qw/USE_INOTIFY/;
ok(!USE_INOTIFY(), "Linux::Inotify2 is blocked");

use IPC::Manager::Test::ClientMessageFiles;
IPC::Manager::Test::ClientMessageFiles::run_tests();

done_testing;
