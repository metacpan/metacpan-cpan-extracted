package Mesos::Executor;
use Moo;
use strict;
use warnings;

with 'Mesos::Role::Executor';

sub registered {}
sub reregistered {}
sub disconnected {}
sub launchTask {}
sub killTask {}
sub frameworkMessage {}
sub shutdown {}
sub error {}


=head1 NAME

Mesos::Executor - base class for Mesos executors

=head1 SYNOPSIS

Mesos::Executor methods are callbacks which will are invoked by Mesos::ExecutorDriver.

=head1 METHODS

=over 4

=item registered($driver, $executorInfo, $frameworkInfo, $slaveInfo)

=item reregistered($driver, $slaveInfo)

=item disconnected($driver)

=item launchTask($driver, $task)

=item killTask($driver, $taskId)

=item frameworkMessage($driver, $message)

=item shutdown($driver)

=item error($driver, $message)

=back

=cut

1;
