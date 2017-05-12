package Makefile::Parallel::Scheduler;

use strict;
use warnings;
use Proc::Simple;
use Data::Dumper;

=head1 Sub-system interface

This is the interface any new or old sub-system must obey so it can be
used by the pmake program. Each of the functions is documented.
For a simple implementation where you can learn the details, see
the code of the Local.pm sub-system.

=cut

=head1 new

This function is a constructor, it should return a new object and
do all the initialization stuff it needs to begin accepting jobs.

=cut
sub new {
    my ($class, $self) = @_;

    $self ||= {};
    bless $self, $class;
}

=head1 launch

This function receives a job structure and should launch the job
on the system. This method should not block. The debug variable
is set to true if the user wants you to print or save debug
information.

=cut
sub launch {
    my ($self, $job, $debug) = @_;

    die("launch");
}

=head1 poll

This function should return a boolean, stating if the process
passed as a parameter $job is still running. The logger could
be used to print debug messages.

=cut
sub poll {
    my ($self, $job, $logger) = @_;

    die("poll");
}

=head1 interrupt

This function should be called to force the interruption of
a running process.

=cut
sub interrupt {
    my ($self, $job) = @_;

    die("interrupt");
}

=head1 get_id

This function should simply return the unique ID of this
process.

=cut
sub get_id {
    my ($self, $job) = @_;

    die("get_id");
}

=head1 can_run

If for whatever reason the job specified could not be
run (eg: there is no resources available), you should
return false on the function.

=cut
sub can_run {
    my ($self, $job) = @_;
    
    die("can_run");
}

=head1 clean

Clean any mess you may created. (eg. temporary files).

=cut
sub clean {
    my ($self, $queue) = @_;

    die("clean");
}

=head1 get_dead_job_info

Tries to get any info from the dead job. This function
should *try* to populate the $job->{realtime} and 
$job->{exitstatus}. It is not required however. It should
simply *try* to get this info.

=cut
sub get_dead_job_info {
    my ($self, $job) = @_;

    # *Try* to fill:
    #   $job->{realtime}
    #   $job->{exitstatus}
    die('get_dead_job_info');
}

1;
