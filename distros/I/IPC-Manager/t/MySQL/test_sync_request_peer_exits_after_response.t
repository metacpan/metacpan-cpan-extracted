use Test2::V1 -ipP;
use Test2::IPC;
skip_all "MySQL driver not available" unless eval { require IPC::Manager::Client::MySQL; IPC::Manager::Client::MySQL->viable };
use lib 't/lib';
use IPC::Manager::Test;
IPC::Manager::Test->run_one(protocol => 'MySQL', test => 'test_sync_request_peer_exits_after_response');

done_testing;
