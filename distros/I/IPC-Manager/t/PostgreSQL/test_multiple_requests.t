use Test2::V1 -ipP;
use Test2::IPC;
skip_all "PostgreSQL driver not available" unless eval { require IPC::Manager::Client::PostgreSQL; IPC::Manager::Client::PostgreSQL->viable };
use lib 't/lib';
use IPC::Manager::Test;
IPC::Manager::Test->run_one(protocol => 'PostgreSQL', test => 'test_multiple_requests');

done_testing;
