use Test2::V1 -ipP;
use Test2::IPC;
use lib 't/lib';
use IPC::Manager::Test::DBVersions qw/for_each_db_version/;

for_each_db_version([qw/postgresql/], sub {
    unless (eval { require IPC::Manager::Client::PostgreSQL; IPC::Manager::Client::PostgreSQL->viable }) {
        plan skip_all => "PostgreSQL driver not available";
        return;
    }
    require IPC::Manager::Test;
    IPC::Manager::Test->run_one(protocol => 'PostgreSQL', test => 'test_suspend_and_reconnect');
});

done_testing;
