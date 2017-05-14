#!/usr/bin/perl
package TestScheduler;
use Moo;
use strict;
use warnings;
extends 'Mesos::Scheduler';
use Mesos::Messages;

has TOTAL_TASKS => (is => 'ro', default => 5);
has TOTAL_CPUS => (is => 'ro', default => 1);
has TASK_MEM => (is => 'ro', default => 32);

has executor => (is => 'ro');
has taskData => (is => 'rw', default => sub { {} });
has tasksLaunched => (is => 'rw', default => 0);
has tasksFinished => (is => 'rw', default => 0);
has messagesSent => (is => 'rw', default => 0);
has messagesReceived => (is => 'rw', default => 0);

sub registered {
    my ($self, $driver, $frameworkId, $masterInfo) = @_;
    printf "Registered with framework ID %s\n", $frameworkId->{value};
}

sub resourceOffers {
    my ($self, $driver, $offers) = @_;
    printf "Got %d resource offers\n", scalar @$offers;
    for my $offer (@$offers) {
        my $tasks = [];
        printf "Got resource offer %s\n", $offer->{id}{value};
        if ($self->tasksLaunched < $self->TOTAL_TASKS) {
            my $tid = $self->tasksLaunched;
            $self->tasksLaunched($self->tasksLaunched + 1);
            printf "Accepting offer on %s to start task %d\n", $offer->{hostname}, $tid;
            
            my $task = Mesos::TaskInfo->new({
                task_id   => {value => $tid},
                slave_id  => $offer->{slave_id},
                name      => "task $tid",
                executor  => $self->executor,
                resources => [{
                    name   => "cpus",
                    type   => Mesos::Value::Type::SCALAR,
                    scalar => {value => $self->TOTAL_CPUS},
                }, {
                    name   => "mem",
                    type   => Mesos::Value::Type::SCALAR,
                    scalar => {value => $self->TASK_MEM},
                }],
            });
            
            push @$tasks, $task;
            $self->taskData->{$task->{task_id}{value}} = [
                $offer->{slave_id}, $task->{executor}{executor_id},
            ];
        }
        $driver->launchTasks([$offer->{id}], $tasks);
    }
}

sub statusUpdate {
    my ($self, $driver, $update) = @_;
    printf "Task %s is in state %d\n", $update->{task_id}{value}, $update->{state};

    if ($update->{data} ne "data with a \0 byte") {
        print "The update data did not match!\n";
        print "\tExpected 'data with a \\x00 byte'\n";
        print "\tActual: " . $update->{data} . "\n";
        exit 1;
    }

    if ($update->{state} == Mesos::TaskState::TASK_FINISHED) {
        $self->tasksFinished($self->tasksFinished + 1);
        print "All tasks done, waiting for final framework message\n"
            if $self->tasksFinished == $self->TOTAL_TASKS;

        my ($slave_id, $executor_id) = @{$self->taskData->{$update->{task_id}{value}}||[]};

        $self->messagesSent($self->messagesSent + 1);
        $driver->sendFrameworkMessage(
            $executor_id,
            $slave_id,
            "data with a \0 byte",
        );
    }
}

sub frameworkMessage {
    my ($self, $driver, $executorId, $slaveId, $message) = @_;
    $self->messagesReceived($self->messagesReceived + 1);
    if ($message ne "data with a \0 byte") {
        print "The returned message data did not match!\n";
        print "\tExpected 'data with a \\x00 byte'\n";
        print "\tActual: $message\n";
        exit 1;
    }
    print "Received message: $message\n";
    if ($self->messagesReceived == $self->TOTAL_TASKS) {
        if ($self->messagesReceived != $self->messagesSent) {
            print "Sent " . $self->messagesSent;
            print " but received " . $self->messagesReceived . "\n";
            exit 1;
        }
        print "All tasks done, and all messages received, exiting\n";
        $driver->stop;
    }
}

package main;
use strict;
use warnings;
use Cwd qw(abs_path);
use FindBin qw($Bin);
use Mesos::Messages;
use Mesos::SchedulerDriver;
my $master = shift or die "Usage: $0 master\n";

my $executor = Mesos::ExecutorInfo->new({
    executor_id => {value => "default"},
    command     => {value => abs_path("$Bin/test_executor.pl")},
});

my $framework = Mesos::FrameworkInfo->new({
    user => "",
    name => "Test Framework (Perl)",    
});

if ($ENV{MESOS_CHECKPOINT}) {
    print "Enabling checkpoint for the framework\n";
    $framework->checkpoint(1);
}

my $scheduler = TestScheduler->new(executor => $executor);
my $driver = Mesos::SchedulerDriver->new(
    scheduler => $scheduler,
    framework => $framework,
    master    => $master,
);
exit( ($driver->run == Mesos::Status::DRIVER_STOPPED) ? 0 : 1 );
