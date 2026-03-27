use Test2::V1 -ipP;
use Test2::IPC;

use Test2::Require::Module 'DBI';
use Test2::Require::Module 'DBIx::QuickDB';

use Test2::Tools::QuickDB;
skipall_unless_can_db(driver => 'MySQL');

use Test2::API qw/context/;

BEGIN {
    my $ok = eval { require DBD::MariaDB; 1 };
    $ok ||= eval {require DBD::mysql; 1 };

    unless ($ok) {
        my $ctx = context();
        $ctx->plan(0, SKIP => "Need either DBD::MariaDB or DBD::mysql");
        $ctx->release;
    }
}

{
    no warnings 'once';
    $main::PROTOCOL = 'MySQL';
}

subtest general => sub {
    do './t/generic_test.pl' or die $@;
};

subtest service => sub {
    do './t/service_test.pl' or warn $@;
};

done_testing;
