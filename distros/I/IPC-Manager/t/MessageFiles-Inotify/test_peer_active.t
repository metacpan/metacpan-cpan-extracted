use Test2::V1 -ipP;
use Test2::IPC;
use Test2::Require::Module 'Linux::Inotify2' => '2.3';
use lib 't/lib';
use IPC::Manager::Test;
IPC::Manager::Test->run_one(protocol => 'MessageFiles', test => 'test_peer_active');

done_testing;
