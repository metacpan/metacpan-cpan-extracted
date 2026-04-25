use Test2::V1 -ipP;
use Test2::IPC;
use Test2::Require::Module 'Linux::Inotify2' => '2.3';
use lib 't/lib';
use IPC::Manager::Test;
IPC::Manager::Test->run_one(protocol => 'JSONFile', test => 'test_post_fork_hook');

done_testing;
