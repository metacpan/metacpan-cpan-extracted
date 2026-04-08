use lib 't/lib';
use IPC::Manager::Test::BlockInotify;

use Test2::V0;
use Test2::Require::Module 'Digest::SHA';

use IPC::Manager::Util qw/USE_INOTIFY/;
ok(!USE_INOTIFY(), "Linux::Inotify2 is blocked");

use IPC::Manager::Test::ClientJSONFile;
IPC::Manager::Test::ClientJSONFile::run_tests();

done_testing;
