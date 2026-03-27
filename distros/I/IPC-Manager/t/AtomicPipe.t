use Test2::V1 -ipP;
use Test2::IPC;

use Test2::Require::Module 'Atomic::Pipe';

{
    no warnings 'once';
    $main::PROTOCOL = 'AtomicPipe';
}

subtest general => sub {
    do './t/generic_test.pl' or die $@;
};

subtest service => sub {
    do './t/service_test.pl' or die $@;
};

done_testing;
