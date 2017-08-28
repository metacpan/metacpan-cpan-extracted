package HPC::Runner::Command::stats::Logger::JSON::Summary::TableOutput;

use Moose::Role;
use namespace::autoclean;

with 'HPC::Runner::Command::stats::Logger::JSON::TableOutput';

sub iter_jobs_summary {
    my $self       = shift;
    my $submission = shift;
    my $jobref     = shift;

    my $submission_id = $submission->{uuid};
    my $table         = $self->build_table($submission, $submission_id);
    $table->setCols(
        [ 'JobName', 'Complete', 'Running', 'Success', 'Fail', 'Total' ] );

    foreach my $job ( @{$jobref} ) {
        my $jobname = $job->{job};
        if ( $self->jobname ) {
            next unless $self->jobname eq $jobname;
        }
        my $total_tasks = $job->{total_tasks};

        $self->iter_tasks_summary( $submission_id, $jobname );
        $self->task_data->{$jobname}->{total} = $total_tasks;

        $table->addRow(
            [
                $jobname,
                $self->task_data->{$jobname}->{complete},
                $self->task_data->{$jobname}->{running},
                $self->task_data->{$jobname}->{success},
                $self->task_data->{$jobname}->{fail},
                $self->task_data->{$jobname}->{total},
            ]
        );
        $self->task_data( {} );
    }

    print $table;
    print "\n";
}


1;
