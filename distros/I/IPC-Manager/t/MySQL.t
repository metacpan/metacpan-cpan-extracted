use Test2::V1 -ipP;
use Test2::IPC;
use IPC::Manager::Client::MySQL;

skip_all "MySQL driver not available" unless IPC::Manager::Client::MySQL->viable;

use lib 't/lib';
use IPC::Manager::Test;

IPC::Manager::Test->run_all(protocol => 'MySQL');

done_testing;
