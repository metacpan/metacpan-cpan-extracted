package HPC::Runner::Command::stats::Logger::JSON::Summary::JSONOutput;

use Moose::Role;
use namespace::autoclean;
use JSON;

with 'HPC::Runner::Command::stats::Logger::JSON::JSONOutput';

sub iter_jobs_summary {
    my $self       = shift;
    my $submission = shift;
    my $jobref     = shift;

    my $submission_id = $submission->{uuid};
    my $start_time    = $submission->{submission_time} || '';
    my $project       = $submission->{project} || '';

    my $submission_obj = {};
    $submission_obj->{$submission_id}->{project}         = $project;
    $submission_obj->{$submission_id}->{submission_time} = $start_time;

    my $summary = {};
    foreach my $job ( @{$jobref} ) {
        my $jobname = $job->{job};
        if ( $self->jobname ) {
            next unless $self->jobname eq $jobname;
        }
        my $total_tasks = $job->{total_tasks};

        $self->iter_tasks_summary( $submission_id, $jobname );
        $self->task_data->{$jobname}->{total} = $total_tasks;
        my $summary = $self->gen_job_tasks_summary($jobname);

        $summary->{$jobname}->{total_tasks} = $total_tasks;
        $submission_obj->{$submission_id}->{jobs}->{$jobname} = $summary;

        $self->task_data( {} );
    }

    push( @{ $self->json_data }, $submission_obj );
}

sub gen_job_tasks_summary {
    my $self    = shift;
    my $jobname = shift;

    my $summary = {};
    $summary->{$jobname} = {};

    $summary->{$jobname}->{complete} =
      $self->task_data->{$jobname}->{complete};
    $summary->{$jobname}->{running} =
      $self->task_data->{$jobname}->{running};
    $summary->{$jobname}->{success} =
      $self->task_data->{$jobname}->{success};
    $summary->{$jobname}->{fail} = $self->task_data->{$jobname}->{fail};

    return $summary;

}

1;
