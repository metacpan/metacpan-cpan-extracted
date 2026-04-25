use lib 't/lib';
use IPC::Manager::Test::BlockInotify;
use Test2::V1 -ipP;
use Test2::IPC;
use Test2::Require::Module 'Digest::SHA';
use IPC::Manager::Test;
IPC::Manager::Test->run_one(protocol => 'JSONFile', test => 'test_try_message');

done_testing;
