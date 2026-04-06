use Test2::V0;

use IPC::Manager::DBI;

isa_ok('IPC::Manager::DBI', ['UNIVERSAL'], "IPC::Manager::DBI is a loadable package");
ok($IPC::Manager::DBI::VERSION, "has a VERSION");

done_testing;
