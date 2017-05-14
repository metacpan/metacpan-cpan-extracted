#!/usr/bin/perl
use strict;
use warnings;
use FindBin::libs;
use Test::More;
use Mesos::Test::Utils;

BEGIN {
    plan skip_all => 'require Test::LeakTrace'
        unless eval{ require Test::LeakTrace };
}
use Test::LeakTrace;

use Mesos::SchedulerDriver;
no_leaks_ok {
    my $driver = Mesos::SchedulerDriver->new(
        scheduler => test_scheduler,
        master    => test_master,
        framework => test_framework,
    );
} 'Mesos::SchedulerDriver construction does not leak';

use Mesos::Channel::Pipe;
no_leaks_ok {
    my $channel = Mesos::Channel::Pipe->new;
} 'Mesos::Channel::Pipe construction does not leak';

use Mesos::Messages;
no_leaks_ok {
    my $channel = Mesos::Channel::Pipe->new;
    my $sent_command = "test command";
    my @sent_args = ('string',
                     [qw(array of strings)],
                     Mesos::FrameworkID->new({value => 'single'}),
                     [Mesos::FrameworkID->new({value => 'an'}), Mesos::FrameworkID->new({value => 'array'})]
                  );
    $channel->send($sent_command, @sent_args);
    $channel->recv;
} 'Mesos::Channel::Pipe sent data without leak';

use Mesos::Channel::Interrupt;
no_leaks_ok {
    my $channel = Mesos::Channel::Interrupt->new(callback => sub {});
} 'Mesos::Channel::Interrupt does not leak';

no_leaks_ok {
    my $channel = Mesos::Channel::Interrupt->new(callback => sub {});
    my $sent_command = "test command";
    my @sent_args = ('string',
                     [qw(array of strings)],
                     Mesos::FrameworkID->new({value => 'single'}),
                     [Mesos::FrameworkID->new({value => 'an'}), Mesos::FrameworkID->new({value => 'array'})]
                  );
    $channel->send($sent_command, @sent_args);
    $channel->recv;
} 'Mesos::Channel::Interrupt sent data without leak';


done_testing();
