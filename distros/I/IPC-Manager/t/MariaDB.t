use Test2::V1 -ipP;
use Test2::IPC;
use IPC::Manager::Client::MariaDB;

skip_all "MariaDB driver not available" unless IPC::Manager::Client::MariaDB->viable;

use lib 't/lib';
use IPC::Manager::Test;

IPC::Manager::Test->run_all(protocol => 'MariaDB');

done_testing;
