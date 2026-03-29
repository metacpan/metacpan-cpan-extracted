use Test2::V1 -ipP;
use Test2::IPC;
use Carp::Always;

{
    no warnings 'once';
    $main::PROTOCOL = 'MessageFiles';
}

subtest general => sub {
    do './t/generic_test.pl' or die $@;
};

subtest service => sub {
    do './t/service_test.pl' or die $@;
};

done_testing;
