use Test2::V1 -ipP;
use Test2::IPC;
use Test2::Require::Module 'IO::Socket::UNIX' => '1.55';
use lib 't/lib';
use IPC::Manager::Test;
IPC::Manager::Test->run_one(protocol => 'ConnectionUnix', test => 'test_exec_service');

done_testing;
