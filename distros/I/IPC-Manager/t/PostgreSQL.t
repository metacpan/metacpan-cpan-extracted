use Test2::V1 -ipP;
use Test2::IPC;
use IPC::Manager::Client::PostgreSQL;

skip_all "PostgreSQL driver not available" unless IPC::Manager::Client::PostgreSQL->viable;

use lib 't/lib';
use IPC::Manager::Test;

IPC::Manager::Test->run_all(protocol => 'PostgreSQL');

done_testing;
