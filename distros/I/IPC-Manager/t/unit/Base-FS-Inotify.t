use Test2::V0;
use Test2::Require::Module 'Linux::Inotify2';
use lib 't/lib';

use IPC::Manager::Util qw/USE_INOTIFY/;
ok(USE_INOTIFY(), "Linux::Inotify2 is in use");

use IPC::Manager::Test::BaseFS;
IPC::Manager::Test::BaseFS::run_tests();

done_testing;
