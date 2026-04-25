use Test2::V1 -ipP;
use Test2::IPC;
skip_all "SQLite driver not available" unless eval { require IPC::Manager::Client::SQLite; IPC::Manager::Client::SQLite->viable };
use lib 't/lib';
use IPC::Manager::Test;
IPC::Manager::Test->run_one(protocol => 'SQLite', test => 'test_sync_request_peer_exits_after_response');

done_testing;
