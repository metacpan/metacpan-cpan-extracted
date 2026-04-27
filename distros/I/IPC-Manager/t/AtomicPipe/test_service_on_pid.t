use Test2::V1 -ipP;
use Test2::IPC;
use Test2::Require::Module 'Atomic::Pipe' => '0.026';
use lib 't/lib';
use IPC::Manager::Test;
IPC::Manager::Test->run_one(protocol => 'AtomicPipe', test => 'test_service_on_pid');

done_testing;
