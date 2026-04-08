use Test2::V1 -ipP;
use Test2::IPC;
use Test2::Require::Module 'Linux::Inotify2';

use lib 't/lib';
use IPC::Manager::Test;
IPC::Manager::Test->run_all(protocol => 'JSONFile');

done_testing;
