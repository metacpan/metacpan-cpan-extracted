package HPC::Runner::Command::stats::Logger::JSON::Long::TableOutput;

use Moose::Role;
use namespace::autoclean;

with 'HPC::Runner::Command::stats::Logger::JSON::TableOutput';

use JSON;
use Text::ASCIITable;

sub iter_jobs_long {
    my $self       = shift;
    my $submission = shift;
    my $jobref     = shift;

    my $submission_id = $submission->{uuid};
    my $table         = $self->build_table($submission, $submission_id);

    $table->setCols(
        [
            'Jobname',
            'TaskID',
            'Task Tags',
            'Start Time',
            'End Time',
            'Duration',
            'Exit Code'
        ]
    );

    foreach my $job ( @{$jobref} ) {
        my $jobname = $job->{job};

        if ( $self->jobname ) {
            next unless $self->jobname eq $jobname;
        }
        my $total_tasks = $job->{total_tasks};

        my $tasks = $self->get_tasks( $submission_id, $jobname );
        $self->iter_tasks_long( $jobname, $tasks, $table );

        $self->task_data( {} );
    }

    print $table;
    print "\n";
}

sub iter_tasks_long {
    my $self    = shift;
    my $jobname = shift;
    my $tasks   = shift;
    my $table   = shift;

    foreach my $task ( @{$tasks} ) {

        my $task_tags  = $task->{task_tags}  || '';
        my $start_time = $task->{start_time} || '';

        my $end_time = $task->{exit_time} || '';
        my $duration = $task->{duration}  || '';
        my $exit_code = $task->{exit_code};
        my $task_id = $task->{task_id} || '';

        if ( !defined $exit_code ) {
            $exit_code = '';
        }

        $table->addRow(
            [
                $jobname,  $task_id,  $task_tags, $start_time,
                $end_time, $duration, $exit_code,
            ]
        );

    }
}

1;
