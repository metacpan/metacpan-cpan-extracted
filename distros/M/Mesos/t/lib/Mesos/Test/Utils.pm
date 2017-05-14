package Mesos::Test::Utils;
use strict;
use warnings;
use Mesos::Messages;
use Mesos::Test::Scheduler;
use Mesos::Test::Executor;
use parent 'Exporter';
our @EXPORT = qw(test_master test_framework test_scheduler test_executor);
our @EXPORT_OK = @EXPORT;


sub test_master {
    return $ENV{TEST_MESOS_MASTER} || '127.0.0.1:5050';
}

sub test_framework {
    return Mesos::FrameworkInfo->new({
        user => 'Mesos_test_user',
        name => 'Mesos_test_name',
    });
}

sub test_scheduler {
    return Mesos::Test::Scheduler->new;
}

sub test_executor {
    return Mesos::Test::Executor->new;
}

1;
