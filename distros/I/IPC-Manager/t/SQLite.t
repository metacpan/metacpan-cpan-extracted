use Test2::V1 -ipP;
use Test2::IPC;
use IPC::Manager::Client::SQLite;

skip_all "SQLite driver not available" unless IPC::Manager::Client::SQLite->viable;

use lib 't/lib';
use IPC::Manager::Test;

IPC::Manager::Test->run_all(protocol => 'SQLite');

done_testing;
