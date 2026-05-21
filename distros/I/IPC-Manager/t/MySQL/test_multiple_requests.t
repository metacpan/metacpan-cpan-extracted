use Test2::V1 -ipP;
use Test2::IPC;
use lib 't/lib';
use IPC::Manager::Test::DBVersions qw/for_each_db_version/;

for_each_db_version([qw/mysql percona/], sub {
    unless (eval { require IPC::Manager::Client::MySQL; IPC::Manager::Client::MySQL->viable }) {
        plan skip_all => "MySQL driver not available";
        return;
    }
    require IPC::Manager::Test;
    IPC::Manager::Test->run_one(protocol => 'MySQL', test => 'test_multiple_requests');
});

done_testing;
