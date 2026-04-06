use Test2::V1 -ipP;
use Test2::IPC;
use Test2::Require::Module 'IPC::SysV' => '2.09';

use lib 't/lib';
use IPC::Manager::Test;
IPC::Manager::Test->run_all(protocol => 'SharedMem');

done_testing;
