use Test2::V1 -ipP;
use Test2::IPC;
skip_all "MariaDB driver not available" unless eval { require IPC::Manager::Client::MariaDB; IPC::Manager::Client::MariaDB->viable };
use lib 't/lib';
use IPC::Manager::Test;
IPC::Manager::Test->run_one(protocol => 'MariaDB', test => 'test_intercept_errors');

done_testing;
