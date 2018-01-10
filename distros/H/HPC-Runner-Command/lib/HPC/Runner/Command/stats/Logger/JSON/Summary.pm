package HPC::Runner::Command::stats::Logger::JSON::Summary;

use Moose::Role;
use namespace::autoclean;

with 'HPC::Runner::Command::stats::Logger::JSON::Utils';

use JSON;
use Try::Tiny;
use File::Slurp;

##This is probably mostly the same across plugins
sub iter_tasks_summary {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;

    my $tasks = $self->read_json_files( $submission_id, $jobname );
    my $running =
      $self->count_running_tasks( $submission_id, $jobname, $tasks );
    my $success = $self->count_successful_tasks(  $submission_id, $jobname, $tasks );
    my $fail = $self->count_failed_tasks(  $submission_id, $jobname, $tasks );
    my $complete = $success + $fail;

    $self->task_data->{$jobname} = {
        complete => $complete,
        success  => $success,
        fail     => $fail,
        running  => $running
    };
}

sub count_running_tasks {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;
    my $tasks         = shift;

    my @task_ids = keys %{$tasks};
    my $running  = 0;

    foreach my $task_id (@task_ids) {
        my $task = $tasks->{$task_id};
        $running++ unless exists $task->{exit_code};
    }

    return $running;
}

sub get_running_tasks {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;
    my $tasks         = shift;

    my @task_ids = keys %{$tasks};
    my $running  = {};

    foreach my $task_id (@task_ids) {
        my $task = $tasks->{$task_id};
        if ( !exists $task->{exit_code} ) {
            $running->{$task_id} = $task;
        }
    }

    return $running;
}

sub get_completed_tasks {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;
    my $tasks         = shift;

    my @task_ids = keys %{$tasks};
    my $complete = {};

    foreach my $task_id (@task_ids) {
        my $task = $tasks->{$task_id};
        if ( exists $task->{exit_code} ) {
            $complete->{$task_id} = $task;
        }
    }

    return $complete;
}

sub count_successful_tasks {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;
    my $tasks         = shift;

    return $self->search_complete( $tasks, $jobname, 1 );
}

sub count_failed_tasks {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;
    my $tasks         = shift;

    return $self->search_complete( $tasks, $jobname, 0 );
}

=head3 search_complete

See which jobs completed successfully

=cut

sub search_complete {
    my $self    = shift;
    my $tasks   = shift;
    my $jobname = shift;
    my $success = shift;

    return 0 unless $tasks;
    return $self->look_for_exit_code( $tasks, $success );
}

sub look_for_exit_code {
    my $self     = shift;
    my $complete = shift;
    my $success  = shift;

    my $task_count = 0;
    foreach my $task ( keys %{$complete} ) {
        my $task_data = $complete->{$task};

        if ( $success && $task_data->{exit_code} == 0 ) {
            $task_count++;
        }
        elsif ( !$success && $task_data->{exit_code} != 0 ) {
            $task_count++;
        }
    }

    return $task_count;
}

1;
