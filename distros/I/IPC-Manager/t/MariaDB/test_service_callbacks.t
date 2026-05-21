use Test2::V1 -ipP;
use Test2::IPC;
use lib 't/lib';
use IPC::Manager::Test::DBVersions qw/for_each_db_version/;

for_each_db_version([qw/mariadb/], sub {
    unless (eval { require IPC::Manager::Client::MariaDB; IPC::Manager::Client::MariaDB->viable }) {
        plan skip_all => "MariaDB driver not available";
        return;
    }
    require IPC::Manager::Test;
    IPC::Manager::Test->run_one(protocol => 'MariaDB', test => 'test_service_callbacks');
});

done_testing;
