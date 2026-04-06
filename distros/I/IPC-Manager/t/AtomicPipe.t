use Test2::V1 -ipP;
use Test2::IPC;

use Test2::Require::Module 'Atomic::Pipe';

use lib 't/lib';
use IPC::Manager::Test;
IPC::Manager::Test->run_all(protocol => 'AtomicPipe');

done_testing;
