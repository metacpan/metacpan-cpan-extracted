use Test2::V1 -ipP;
use Test2::IPC;
use Test2::Require::Module 'Atomic::Pipe' => '0.022';
use lib 't/lib';
use IPC::Manager::Test;
IPC::Manager::Test->run_one(protocol => 'AtomicPipe', test => 'test_child_pid_interpose');

done_testing;
