use lib 't/lib';
use IPC::Manager::Test::BlockInotify;
use Test2::V1 -ipP;
use Test2::IPC;
use IPC::Manager::Test;
IPC::Manager::Test->run_one(protocol => 'MessageFiles', test => 'test_service_signal_handling');

done_testing;
